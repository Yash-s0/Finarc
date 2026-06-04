class CounterpartyNormalizer {
  static final RegExp _upiHandlePattern = RegExp(
    r'([a-z0-9._-]{2,})@([a-z0-9._-]{2,})',
    caseSensitive: false,
  );

  static final RegExp _symbolPattern = RegExp(r'[^a-z0-9 ]');
  static final RegExp _spacesPattern = RegExp(r'\s+');

  static const Set<String> _noiseWords = {
    'upi',
    'bank',
    'account',
    'ac',
    'txn',
    'transaction',
    'ref',
    'rrn',
    'from',
    'to',
    'via',
    'paid',
    'sent',
    'received',
    'credited',
    'debited',
    'ending',
    'a',
    'c',
    'bal',
    'avl',
    'available',
    'info',
    'payment',
    'that',
    'fast',
    'check',
    'balance',
    'tap',
    'open',
    'link',
    'mark',
    'read',
    'not',
    'you',
    'avoid',
    'charges',
    'before',
    'last',
    'date',
  };

  static String normalize(String input) {
    if (input.trim().isEmpty) return '';
    var text = input.toLowerCase();
    text = text.replaceAllMapped(_upiHandlePattern, (match) {
      final local = match.group(1) ?? '';
      final domain = match.group(2) ?? '';
      return '$local $domain';
    });
    text = text.replaceAll(_symbolPattern, ' ');
    text = text.replaceAll(_spacesPattern, ' ').trim();
    if (text.isEmpty) return '';

    final filtered = text
        .split(' ')
        .where((token) => token.isNotEmpty && !_noiseWords.contains(token))
        .toList(growable: false);
    return filtered.join(' ');
  }

  static bool isSameOrNearMatch(String a, String b) {
    final left = normalize(a);
    final right = normalize(b);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    if (left.contains(right) || right.contains(left)) {
      return left.length >= 6 && right.length >= 6;
    }
    return _jaccard(left, right) >= 0.8;
  }

  static double _jaccard(String a, String b) {
    final setA = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final setB = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (setA.isEmpty || setB.isEmpty) return 0;
    return setA.intersection(setB).length / setA.union(setB).length;
  }
}
