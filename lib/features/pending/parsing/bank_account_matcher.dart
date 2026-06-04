import '../../../core/database/app_database.dart';

class BankAccountMatchResult {
  const BankAccountMatchResult({
    this.accountId,
    this.matchedLast4,
    this.matchCount = 0,
  });

  final int? accountId;
  final String? matchedLast4;
  final int matchCount;

  bool get isAmbiguous => accountId == null && matchCount > 1;
}

class BankAccountMatcher {
  static BankAccountMatchResult match({
    required Iterable<BankAccount> accounts,
    required String? sourceHint,
  }) {
    if (sourceHint == null || sourceHint.trim().isEmpty) {
      return const BankAccountMatchResult();
    }

    final normalizedHint = _normalize(sourceHint);
    final hintedLast4 = _extractLast4(sourceHint);
    final scored = <({BankAccount account, int score})>[];

    for (final account in accounts) {
      final bankName = _normalize(account.bankName);
      final accountName = _normalize(account.accountName);
      final accountLast4 = _normalizeLast4(account.last4);

      var score = 0;
      if (bankName.isNotEmpty && normalizedHint.contains(bankName)) score += 2;
      if (accountName.isNotEmpty && normalizedHint.contains(accountName)) {
        score += 1;
      }
      if (hintedLast4 != null && accountLast4 == hintedLast4) {
        score += 4;
      }
      if (score > 0) {
        scored.add((account: account, score: score));
      }
    }

    if (scored.isEmpty) {
      return BankAccountMatchResult(matchedLast4: hintedLast4, matchCount: 0);
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final bestScore = scored.first.score;
    final best = scored.where((row) => row.score == bestScore).toList();
    if (best.length == 1) {
      return BankAccountMatchResult(
        accountId: best.first.account.id,
        matchedLast4: hintedLast4,
        matchCount: 1,
      );
    }

    return BankAccountMatchResult(
      matchedLast4: hintedLast4,
      matchCount: best.length,
    );
  }

  static String? extractLast4(String? sourceHint) => _extractLast4(sourceHint);

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String? _normalizeLast4(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 4) return null;
    return digits;
  }

  static String? _extractLast4(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final match = RegExp(r'(\d{4})\b').firstMatch(input);
    return match?.group(1);
  }
}
