import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import 'notification_ingestion_service.dart';

enum MissedMessageSampleFilter {
  all('All'),
  billDue('Bill due'),
  cardPayment('Card payment'),
  walletBalance('Wallet balance'),
  manualPaste('Manual paste'),
  parserFailed('Parser failed');

  const MissedMessageSampleFilter(this.label);

  final String label;
}

class MissedMessageSampleService {
  const MissedMessageSampleService(this._db);

  final AppDatabase _db;

  Future<void> recordFromDebugEntry(
    NotificationDebugEntry entry, {
    int createdPendingCount = 0,
  }) async {
    if (!isLearningSample(entry)) return;

    final now = DateTime.now();
    final sampleType = classify(entry);
    final parseResult = entry.parseResult ?? entry.result;
    final fingerprint = buildFingerprint(entry, sampleType: sampleType);
    final existing = await (_db.select(
      _db.missedMessageSamples,
    )..where((row) => row.fingerprint.equals(fingerprint))).getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.missedMessageSamples,
      )..where((row) => row.id.equals(existing.id))).write(
        MissedMessageSamplesCompanion(
          title: Value(_nullable(entry.title)),
          sampleText: Value(entry.bodyPreview),
          decision: Value(entry.decision),
          reason: Value(entry.reason),
          parseResult: Value(parseResult),
          providerName: Value(_nullable(entry.providerName)),
          confidenceScore: Value(entry.confidenceScore),
          confidenceLevel: Value(_nullable(entry.confidenceLevel)),
          candidateCount: Value(entry.candidateCount),
          amountCandidate: Value(_nullable(entry.amountCandidate)),
          blockedContext: Value(_nullable(entry.blockedContext)),
          duplicateDecision: Value(_nullable(entry.duplicateDecision)),
          possibleDuplicateReason: Value(
            _nullable(entry.possibleDuplicateReason),
          ),
          transactionDateChosen: Value(entry.transactionDateChosen),
          createdPendingCount: Value(
            existing.createdPendingCount + createdPendingCount,
          ),
          seenCount: Value(existing.seenCount + 1),
          lastSeenAt: Value(entry.receivedAt),
        ),
      );
      return;
    }

    await _db
        .into(_db.missedMessageSamples)
        .insert(
          MissedMessageSamplesCompanion.insert(
            fingerprint: fingerprint,
            sampleType: sampleType,
            sourceType: _emptyAsUnknown(entry.sourceType),
            packageName: _emptyAsUnknown(entry.packageName),
            sampleText: entry.bodyPreview,
            decision: entry.decision,
            reason: entry.reason,
            parseResult: parseResult,
            sender: Value(_nullable(entry.sender)),
            title: Value(_nullable(entry.title)),
            providerName: Value(_nullable(entry.providerName)),
            confidenceScore: Value(entry.confidenceScore),
            confidenceLevel: Value(_nullable(entry.confidenceLevel)),
            candidateCount: Value(entry.candidateCount),
            amountCandidate: Value(_nullable(entry.amountCandidate)),
            blockedContext: Value(_nullable(entry.blockedContext)),
            duplicateDecision: Value(_nullable(entry.duplicateDecision)),
            possibleDuplicateReason: Value(
              _nullable(entry.possibleDuplicateReason),
            ),
            transactionDateChosen: Value(entry.transactionDateChosen),
            createdPendingCount: Value(createdPendingCount),
            lastSeenAt: entry.receivedAt,
            createdAt: Value(now),
          ),
        );
  }

  Future<List<MissedMessageSample>> listSamples({
    MissedMessageSampleFilter filter = MissedMessageSampleFilter.all,
  }) async {
    final rows =
        await (_db.select(_db.missedMessageSamples)
              ..orderBy([
                (row) => OrderingTerm(
                  expression: row.lastSeenAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(250))
            .get();
    if (filter == MissedMessageSampleFilter.all) {
      return rows;
    }
    final type = _typeForFilter(filter);
    return rows.where((row) => row.sampleType == type).toList(growable: false);
  }

  Future<Map<MissedMessageSampleFilter, int>> countsByFilter() async {
    final rows = await (_db.select(_db.missedMessageSamples)).get();
    final counts = <MissedMessageSampleFilter, int>{
      for (final filter in MissedMessageSampleFilter.values) filter: 0,
    };
    counts[MissedMessageSampleFilter.all] = rows.length;
    for (final row in rows) {
      final filter = _filterForType(row.sampleType);
      counts[filter] = (counts[filter] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> clearSamples() async {
    await _db.delete(_db.missedMessageSamples).go();
  }

  Future<File> exportSamplesJsonl() async {
    final rows = await listSamples();
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(jsonEncode(_toJson(row)));
    }
    final file = File(p.join(await _exportDirectory(), _exportFileName()));
    await file.parent.create(recursive: true);
    return file.writeAsString(buffer.toString(), flush: true);
  }

  static bool isLearningSample(NotificationDebugEntry entry) {
    if (entry.sourceType == 'manualPaste') return true;
    if (entry.decision == 'pending-created') return false;
    final type = classify(entry);
    if (type == 'bill_due' ||
        type == 'card_payment' ||
        type == 'wallet_balance') {
      return true;
    }
    if (entry.decision == 'ignored' || entry.decision == 'duplicate') {
      return true;
    }
    return entry.reason == 'parser-no-candidate' ||
        entry.reason == 'confidence-low' ||
        entry.parseResult == 'parser-failed' ||
        entry.parseResult == 'parsed-low-confidence';
  }

  static String classify(NotificationDebugEntry entry) {
    final reason = entry.reason.toLowerCase();
    final parse = (entry.parseResult ?? entry.result).toLowerCase();
    final source = entry.sourceType.toLowerCase();
    final text = '${entry.title} ${entry.packageName} ${entry.bodyPreview}'
        .toLowerCase();

    if (source == 'manualpaste') return 'manual_paste';
    if (reason.contains('card-bill-due') ||
        parse.contains('card-bill-due') ||
        (text.contains('bill') && text.contains('due'))) {
      return 'bill_due';
    }
    if (reason.contains('card-payment') ||
        parse.contains('card-payment') ||
        text.contains('credit card payment')) {
      return 'card_payment';
    }
    if (text.contains('wallet balance') ||
        text.contains('amazon pay balance') ||
        text.contains('updated balance')) {
      return 'wallet_balance';
    }
    if (reason.contains('parser-no-candidate') ||
        parse == 'parser-failed' ||
        parse.contains('low-confidence')) {
      return 'parser_failed';
    }
    return 'parser_failed';
  }

  static bool matchesFilter(
    MissedMessageSample sample,
    MissedMessageSampleFilter filter,
  ) {
    if (filter == MissedMessageSampleFilter.all) return true;
    return sample.sampleType == _typeForFilter(filter);
  }

  static String buildFingerprint(
    NotificationDebugEntry entry, {
    required String sampleType,
  }) {
    final text = [
      sampleType,
      entry.sourceType,
      entry.packageName,
      entry.sender ?? '',
      entry.reason,
      entry.parseResult ?? entry.result,
      _normalizeForFingerprint(entry.bodyPreview),
    ].join('|');
    return _stableHash(text);
  }

  static String _typeForFilter(MissedMessageSampleFilter filter) {
    return switch (filter) {
      MissedMessageSampleFilter.all => 'all',
      MissedMessageSampleFilter.billDue => 'bill_due',
      MissedMessageSampleFilter.cardPayment => 'card_payment',
      MissedMessageSampleFilter.walletBalance => 'wallet_balance',
      MissedMessageSampleFilter.manualPaste => 'manual_paste',
      MissedMessageSampleFilter.parserFailed => 'parser_failed',
    };
  }

  static MissedMessageSampleFilter _filterForType(String type) {
    return switch (type) {
      'bill_due' => MissedMessageSampleFilter.billDue,
      'card_payment' => MissedMessageSampleFilter.cardPayment,
      'wallet_balance' => MissedMessageSampleFilter.walletBalance,
      'manual_paste' => MissedMessageSampleFilter.manualPaste,
      _ => MissedMessageSampleFilter.parserFailed,
    };
  }

  static String _normalizeForFingerprint(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _stableHash(String text) {
    var hash = 0x811c9dc5;
    for (final codeUnit in text.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _emptyAsUnknown(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'unknown' : trimmed;
  }

  static String? _nullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static Map<String, Object?> _toJson(MissedMessageSample row) {
    return <String, Object?>{
      'id': row.id,
      'fingerprint': row.fingerprint,
      'sampleType': row.sampleType,
      'sourceType': row.sourceType,
      'packageName': row.packageName,
      'sender': row.sender,
      'title': row.title,
      'sampleText': row.sampleText,
      'decision': row.decision,
      'reason': row.reason,
      'parseResult': row.parseResult,
      'providerName': row.providerName,
      'confidenceScore': row.confidenceScore,
      'confidenceLevel': row.confidenceLevel,
      'candidateCount': row.candidateCount,
      'amountCandidate': row.amountCandidate,
      'blockedContext': row.blockedContext,
      'duplicateDecision': row.duplicateDecision,
      'possibleDuplicateReason': row.possibleDuplicateReason,
      'transactionDateChosen': row.transactionDateChosen?.toIso8601String(),
      'createdPendingCount': row.createdPendingCount,
      'seenCount': row.seenCount,
      'lastSeenAt': row.lastSeenAt.toIso8601String(),
      'createdAt': row.createdAt.toIso8601String(),
    };
  }

  static String _exportFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return 'missed_message_samples_$timestamp.jsonl';
  }

  Future<String> _exportDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    return p.join(baseDir.path, 'exports');
  }
}
