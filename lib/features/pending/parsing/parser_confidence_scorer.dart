class ParserConfidenceScorer {
  static double score({
    required bool hasAmount,
    required bool hasMerchant,
    required bool hasSourceHint,
    required bool hasPatternMatch,
    required bool hasDate,
    required bool isFallback,
  }) {
    if (!hasAmount) return 0;

    var value = 0.0;
    if (hasAmount) value += 0.45;
    if (hasMerchant) value += 0.20;
    if (hasSourceHint) value += 0.12;
    if (hasPatternMatch) value += 0.12;
    if (hasDate) value += 0.06;
    if (isFallback) value -= 0.15;

    if (value < 0.4) value = 0.4;
    if (value > 0.98) value = 0.98;
    return value;
  }
}
