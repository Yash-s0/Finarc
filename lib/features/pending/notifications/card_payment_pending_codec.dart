class CardPaymentPendingData {
  const CardPaymentPendingData({
    this.issuer,
    this.cardLast4,
    this.destinationCardId,
    this.sourceHint,
    this.sourceAccountId,
    this.sourceTypeSuggestion,
    this.transactionRef,
    this.kinds = const <String>[],
  });

  final String? issuer;
  final String? cardLast4;
  final int? destinationCardId;
  final String? sourceHint;
  final int? sourceAccountId;
  final String? sourceTypeSuggestion;
  final String? transactionRef;
  final List<String> kinds;

  static const String markerPrefix = '[CARD_PAYMENT|';

  bool get hasMarkerData =>
      issuer != null ||
      cardLast4 != null ||
      destinationCardId != null ||
      sourceHint != null ||
      sourceAccountId != null ||
      sourceTypeSuggestion != null ||
      transactionRef != null ||
      kinds.isNotEmpty;

  CardPaymentPendingData copyWith({
    String? issuer,
    String? cardLast4,
    int? destinationCardId,
    bool clearDestinationCardId = false,
    String? sourceHint,
    int? sourceAccountId,
    bool clearSourceAccountId = false,
    String? sourceTypeSuggestion,
    String? transactionRef,
    List<String>? kinds,
  }) {
    return CardPaymentPendingData(
      issuer: issuer ?? this.issuer,
      cardLast4: cardLast4 ?? this.cardLast4,
      destinationCardId: clearDestinationCardId
          ? null
          : destinationCardId ?? this.destinationCardId,
      sourceHint: sourceHint ?? this.sourceHint,
      sourceAccountId: clearSourceAccountId
          ? null
          : sourceAccountId ?? this.sourceAccountId,
      sourceTypeSuggestion: sourceTypeSuggestion ?? this.sourceTypeSuggestion,
      transactionRef: transactionRef ?? this.transactionRef,
      kinds: kinds ?? this.kinds,
    );
  }
}

class CardPaymentPendingCodec {
  static String wrap({
    required String rawText,
    required CardPaymentPendingData data,
  }) {
    final encoded = _encode(data);
    if (encoded == null) return rawText;
    return '$encoded\n${strip(rawText)}';
  }

  static CardPaymentPendingData? tryDecode(String rawText) {
    final firstNewline = rawText.indexOf('\n');
    final firstLine = firstNewline == -1
        ? rawText.trim()
        : rawText.substring(0, firstNewline).trim();
    if (!firstLine.startsWith(CardPaymentPendingData.markerPrefix) ||
        !firstLine.endsWith(']')) {
      return null;
    }

    final payload = firstLine.substring(
      CardPaymentPendingData.markerPrefix.length,
      firstLine.length - 1,
    );
    final fields = <String, String>{};
    for (final part in payload.split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final key = part.substring(0, eq).trim();
      final value = Uri.decodeComponent(part.substring(eq + 1).trim());
      fields[key] = value;
    }

    final kinds = (fields['kinds'] ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return CardPaymentPendingData(
      issuer: _blankToNull(fields['issuer']),
      cardLast4: _blankToNull(fields['cardLast4']),
      destinationCardId: int.tryParse(fields['destinationCardId'] ?? ''),
      sourceHint: _blankToNull(fields['sourceHint']),
      sourceAccountId: int.tryParse(fields['sourceAccountId'] ?? ''),
      sourceTypeSuggestion: _blankToNull(fields['sourceTypeSuggestion']),
      transactionRef: _blankToNull(fields['transactionRef']),
      kinds: kinds,
    );
  }

  static String strip(String rawText) {
    final decoded = tryDecode(rawText);
    if (decoded == null) return rawText;
    final firstNewline = rawText.indexOf('\n');
    if (firstNewline == -1) return '';
    return rawText.substring(firstNewline + 1).trim();
  }

  static String appendAuditText(String existingRawText, String nextText) {
    final body = strip(existingRawText);
    final normalizedNext = nextText.trim();
    if (normalizedNext.isEmpty) return existingRawText;
    if (body.contains(normalizedNext)) return existingRawText;

    final data = tryDecode(existingRawText);
    final mergedBody = body.isEmpty
        ? normalizedNext
        : '$body\n---\n$normalizedNext';
    return data == null ? mergedBody : wrap(rawText: mergedBody, data: data);
  }

  static String? _encode(CardPaymentPendingData data) {
    if (!data.hasMarkerData) return null;
    final parts = <String>[];
    void add(String key, Object? value) {
      if (value == null) return;
      final raw = value.toString().trim();
      if (raw.isEmpty) return;
      parts.add('$key=${Uri.encodeComponent(raw)}');
    }

    add('issuer', data.issuer);
    add('cardLast4', data.cardLast4);
    add('destinationCardId', data.destinationCardId);
    add('sourceHint', data.sourceHint);
    add('sourceAccountId', data.sourceAccountId);
    add('sourceTypeSuggestion', data.sourceTypeSuggestion);
    add('transactionRef', data.transactionRef);
    if (data.kinds.isNotEmpty) {
      add('kinds', data.kinds.join(','));
    }
    return '${CardPaymentPendingData.markerPrefix}${parts.join(';')}]';
  }

  static String? _blankToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
