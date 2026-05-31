import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../expenses/data/transaction_engine.dart';
import '../../expenses/models/transaction_types.dart';
import 'transaction_import_models.dart';

class TransactionImportService {
  const TransactionImportService(this._db, this._engine);

  final AppDatabase _db;
  final TransactionEngine _engine;

  Future<TransactionImportParseResult> parsePreview(String jsonText) async {
    final root = _decodeRoot(jsonText);
    if (root == null) {
      return const TransactionImportParseResult(
        isValidJson: false,
        message: 'Invalid JSON. Expected an object with a transactions array.',
      );
    }

    final rowsRaw = root['transactions'];
    if (rowsRaw is! List) {
      return const TransactionImportParseResult(
        isValidJson: false,
        message: 'Invalid JSON format. "transactions" must be a list.',
      );
    }

    final sources = await _loadSources();
    final existingTransactions = await _db.select(_db.transactions).get();
    final previewRows = <TransactionImportPreviewRow>[];
    var totalExpense = 0.0;
    var totalIncome = 0.0;
    final seenImportKeys = <String>{};

    for (var i = 0; i < rowsRaw.length; i++) {
      final rowNumber = i + 1;
      final raw = rowsRaw[i];
      if (raw is! Map) {
        previewRows.add(
          TransactionImportPreviewRow(
            rowNumber: rowNumber,
            raw: const {},
            issues: const [
              TransactionImportValidationIssue(
                message: 'Row is not a JSON object.',
              ),
            ],
          ),
        );
        continue;
      }

      final data = raw.map((key, value) => MapEntry(key.toString(), value));
      final issues = <TransactionImportValidationIssue>[];

      final date = _parseDate(data['date']);
      if (date == null) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'date is required and must be a valid ISO date string.',
          ),
        );
      }

      final amount = _toDouble(data['amount']);
      if (amount == null || amount <= 0) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'amount must be greater than 0.',
          ),
        );
      }

      final importType = _normalizeType(data['type']);
      if (importType == null) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'type must be either expense or income.',
          ),
        );
      }

      final title = (data['title'] ?? '').toString().trim();
      if (title.isEmpty) {
        issues.add(
          const TransactionImportValidationIssue(message: 'title is required.'),
        );
      }

      final paymentMode = _normalizeMode(data['paymentMode']);
      if (paymentMode == null) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'paymentMode must be cash, bank, card, or upi.',
          ),
        );
      }

      final forOthers = _toBool(data['forOthers']) ?? false;
      final personName = (data['personName'] ?? '').toString().trim();
      if (forOthers && personName.isEmpty) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'personName is required when forOthers is true.',
          ),
        );
      }

      final cashbackRaw = _toDouble(data['cashback']) ?? 0;
      final recoveredRaw = _toDouble(data['recoveredAmount']) ?? 0;

      if (importType == 'income' && forOthers) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'forOthers is supported only for expense rows.',
          ),
        );
      }

      if (paymentMode == PaymentSourceType.creditCard &&
          importType == 'income') {
        issues.add(
          const TransactionImportValidationIssue(
            message:
                'Card is not supported as an income destination in current app flow.',
          ),
        );
      }

      SourceMatch? sourceMatch;
      if (paymentMode != null) {
        sourceMatch = _resolveSource(
          mode: paymentMode,
          sourceName: data['sourceName']?.toString(),
          sources: sources,
        );
        issues.addAll(sourceMatch.issues);
      }

      final hasHardError = issues.any((issue) => issue.isWarning == false);
      if (hasHardError ||
          date == null ||
          amount == null ||
          importType == null ||
          paymentMode == null ||
          sourceMatch == null ||
          sourceMatch.sourceId == null) {
        previewRows.add(
          TransactionImportPreviewRow(
            rowNumber: rowNumber,
            raw: data,
            issues: issues,
          ),
        );
        continue;
      }

      final cashback = importType == 'expense'
          ? cashbackRaw.clamp(0, amount).toDouble()
          : 0.0;
      if (importType == 'income' && cashbackRaw > 0) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'cashback is ignored for income rows.',
            isWarning: true,
          ),
        );
      }
      if (paymentMode == PaymentSourceType.cash && cashbackRaw > 0) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'cashback is ignored for cash mode rows.',
            isWarning: true,
          ),
        );
      }

      final recoverableBase = forOthers
          ? (amount - cashback).clamp(0, amount).toDouble()
          : 0.0;
      final recoveredAmount = forOthers
          ? recoveredRaw.clamp(0, recoverableBase).toDouble()
          : 0.0;
      if (forOthers && recoveredRaw > recoverableBase) {
        issues.add(
          const TransactionImportValidationIssue(
            message:
                'recoveredAmount exceeds recoverable amount and was clamped.',
            isWarning: true,
          ),
        );
      }
      final matchedSourceId = sourceMatch.sourceId!;

      final normalizedTitle = _normalize(title);
      final duplicateExists = existingTransactions.any((txn) {
        if ((txn.amount - amount).abs() > 0.009) return false;
        if (txn.paymentSourceType != paymentMode) return false;
        if (txn.paymentSourceId != matchedSourceId) return false;
        if (_normalize(txn.title) != normalizedTitle) return false;
        return _sameDay(txn.transactionDate, date);
      });

      final importDuplicateKey = [
        date.toIso8601String(),
        amount.toStringAsFixed(2),
        normalizedTitle,
        paymentMode,
        matchedSourceId,
      ].join('|');

      if (duplicateExists) {
        issues.add(
          const TransactionImportValidationIssue(
            message:
                'Possible duplicate: same date, amount, title, and source already exists.',
            isWarning: true,
          ),
        );
      }
      if (seenImportKeys.contains(importDuplicateKey)) {
        issues.add(
          const TransactionImportValidationIssue(
            message: 'Possible duplicate within import file.',
            isWarning: true,
          ),
        );
      }
      seenImportKeys.add(importDuplicateKey);

      final category = (data['category'] ?? '').toString().trim();
      final notes = (data['notes'] ?? '').toString().trim();
      final sourceType = paymentMode;
      final transactionType = importType == 'income'
          ? TransactionType.income
          : sourceType == PaymentSourceType.creditCard
          ? TransactionType.creditCard
          : sourceType;

      final input = AddTransactionInput(
        type: transactionType,
        amount: amount,
        title: title,
        category: category.isEmpty
            ? (importType == 'income' ? 'Other' : 'General')
            : category,
        notes: notes.isEmpty ? null : notes,
        transactionDate: date,
        paymentSourceType: sourceType,
        paymentSourceId: matchedSourceId,
        cashbackAmount: sourceType == PaymentSourceType.cash ? 0.0 : cashback,
        isForOthers: forOthers,
        recoverableAmount: forOthers
            ? (recoverableBase - recoveredAmount)
                  .clamp(0, recoverableBase)
                  .toDouble()
            : null,
        recoveredAmount: forOthers ? recoveredAmount : null,
        recoverablePartyName: forOthers ? personName : null,
      );

      if (importType == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }

      previewRows.add(
        TransactionImportPreviewRow(
          rowNumber: rowNumber,
          raw: data,
          issues: issues,
          resolved: TransactionImportResolvedRow(
            rowNumber: rowNumber,
            originalType: importType,
            paymentMode: sourceType,
            sourceId: matchedSourceId,
            sourceLabel: sourceMatch.sourceLabel ?? 'Unknown',
            input: input,
          ),
        ),
      );
    }

    final preview = TransactionImportPreview(
      totalRows: rowsRaw.length,
      rows: previewRows,
      totalExpenseAmount: totalExpense,
      totalIncomeAmount: totalIncome,
      generalWarnings: const [],
    );

    return TransactionImportParseResult(
      isValidJson: true,
      message: 'JSON parsed successfully.',
      preview: preview,
    );
  }

  Future<TransactionImportExecutionResult> importValidRows(
    TransactionImportPreview preview,
  ) async {
    var imported = 0;
    var failed = 0;
    final failureReasons = <String>[];

    for (final row in preview.validResolvedRows) {
      try {
        await _engine.addTransaction(row.input);
        imported += 1;
      } catch (error) {
        failed += 1;
        failureReasons.add('Row ${row.rowNumber}: $error');
      }
    }

    return TransactionImportExecutionResult(
      totalRows: preview.totalRows,
      importedCount: imported,
      skippedCount: preview.invalidRows,
      failedCount: failed,
      failureReasons: failureReasons,
    );
  }

  Future<_ImportSources> _loadSources() async {
    final banks = await _db.select(_db.bankAccounts).get();
    final cards = await _db.select(_db.creditCards).get();
    final wallets = await _db.select(_db.cashWallets).get();
    return _ImportSources(banks: banks, cards: cards, wallets: wallets);
  }

  Map<String, dynamic>? _decodeRoot(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _normalizeType(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'expense' || text == 'income') return text;
    return null;
  }

  String? _normalizeMode(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'cash' || text == 'wallet' || text == 'wallet/cash') {
      return PaymentSourceType.cash;
    }
    if (text == 'bank') return PaymentSourceType.bank;
    if (text == 'upi') return PaymentSourceType.upi;
    if (text == 'card' || text == 'creditcard' || text == 'credit_card') {
      return PaymentSourceType.creditCard;
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  SourceMatch _resolveSource({
    required String mode,
    required String? sourceName,
    required _ImportSources sources,
  }) {
    final catalog = _catalogForMode(mode, sources);
    if (catalog.isEmpty) {
      return SourceMatch(
        issues: [
          TransactionImportValidationIssue(
            message: _emptyStateMessageForMode(mode),
          ),
        ],
      );
    }

    final rawSource = (sourceName ?? '').trim();
    if (rawSource.isEmpty) {
      if (catalog.length == 1) {
        final only = catalog.first;
        return SourceMatch(
          sourceId: only.id,
          sourceLabel: only.label,
          issues: const [
            TransactionImportValidationIssue(
              message:
                  'sourceName missing; auto-selected the only available source.',
              isWarning: true,
            ),
          ],
        );
      }
      return const SourceMatch(
        issues: [
          TransactionImportValidationIssue(
            message:
                'sourceName is required when multiple sources are available for selected paymentMode.',
          ),
        ],
      );
    }

    final normalizedQuery = _normalize(rawSource);
    final exactMatches = catalog
        .where((candidate) {
          final normalizedLabels = candidate.matchTokens.map(_normalize);
          return normalizedLabels.contains(normalizedQuery);
        })
        .toList(growable: false);

    if (exactMatches.length == 1) {
      final match = exactMatches.first;
      return SourceMatch(sourceId: match.id, sourceLabel: match.label);
    }

    final fuzzyMatches = catalog
        .where((candidate) {
          for (final token in candidate.matchTokens) {
            final normalizedToken = _normalize(token);
            if (normalizedToken.contains(normalizedQuery) ||
                normalizedQuery.contains(normalizedToken)) {
              return true;
            }
          }
          return false;
        })
        .toList(growable: false);

    if (fuzzyMatches.length == 1) {
      final match = fuzzyMatches.first;
      return SourceMatch(sourceId: match.id, sourceLabel: match.label);
    }

    if (fuzzyMatches.length > 1 || exactMatches.length > 1) {
      return const SourceMatch(
        issues: [
          TransactionImportValidationIssue(
            message:
                'sourceName matched multiple sources. Use a more specific sourceName.',
          ),
        ],
      );
    }

    return SourceMatch(
      issues: [
        TransactionImportValidationIssue(
          message:
              'sourceName "$rawSource" not found for selected paymentMode.',
        ),
      ],
    );
  }

  List<_SourceCandidate> _catalogForMode(String mode, _ImportSources sources) {
    if (mode == PaymentSourceType.cash) {
      return sources.wallets
          .map(
            (wallet) => _SourceCandidate(
              id: wallet.id,
              label: wallet.walletName,
              matchTokens: [wallet.walletName],
            ),
          )
          .toList(growable: false);
    }

    if (mode == PaymentSourceType.creditCard) {
      return sources.cards
          .map((card) {
            final label = '${card.bankName} • ${card.last4}';
            final tokens = <String>{
              card.bankName,
              card.nickname,
              card.last4,
              card.maskedNumber,
              '${card.bankName} ${card.nickname}',
              '${card.bankName} ${card.last4}',
              label,
            }.where((token) => token.trim().isNotEmpty).toList(growable: false);
            return _SourceCandidate(
              id: card.id,
              label: label,
              matchTokens: tokens,
            );
          })
          .toList(growable: false);
    }

    return sources.banks
        .map((bank) {
          final label = '${bank.accountName} • ${bank.bankName}';
          final tokens = <String>{
            bank.accountName,
            bank.bankName,
            '${bank.bankName} ${bank.accountName}',
            label,
          }.where((token) => token.trim().isNotEmpty).toList(growable: false);
          return _SourceCandidate(
            id: bank.id,
            label: label,
            matchTokens: tokens,
          );
        })
        .toList(growable: false);
  }

  String _emptyStateMessageForMode(String mode) {
    if (mode == PaymentSourceType.cash) {
      return 'No cash wallet found. Add one from Accounts.';
    }
    if (mode == PaymentSourceType.creditCard) {
      return 'No card found. Add one from Cards.';
    }
    if (mode == PaymentSourceType.upi) {
      return 'No UPI/bank account found. Add bank account first.';
    }
    return 'No bank account found. Add one from Accounts.';
  }

  bool _sameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _ImportSources {
  const _ImportSources({
    required this.banks,
    required this.cards,
    required this.wallets,
  });

  final List<BankAccount> banks;
  final List<CreditCard> cards;
  final List<CashWallet> wallets;
}

class _SourceCandidate {
  const _SourceCandidate({
    required this.id,
    required this.label,
    required this.matchTokens,
  });

  final int id;
  final String label;
  final List<String> matchTokens;
}

class SourceMatch {
  const SourceMatch({this.sourceId, this.sourceLabel, this.issues = const []});

  final int? sourceId;
  final String? sourceLabel;
  final List<TransactionImportValidationIssue> issues;
}
