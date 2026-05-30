import 'confidence_level.dart';

class ConfidenceAssessment {
  const ConfidenceAssessment({required this.score, required this.level});

  final double score;
  final ConfidenceLevel level;
}

class ParserConfidenceScorer {
  static ConfidenceAssessment assess({
    required bool hasAmount,
    required bool hasMerchant,
    required bool hasSourceHint,
    required bool hasPatternMatch,
    required bool hasDate,
    required bool isFallback,
  }) {
    if (!hasAmount) {
      return const ConfidenceAssessment(score: 0, level: ConfidenceLevel.low);
    }

    var value = 0.0;
    if (hasAmount) value += 0.45;
    if (hasMerchant) value += 0.20;
    if (hasSourceHint) value += 0.12;
    if (hasPatternMatch) value += 0.12;
    if (hasDate) value += 0.06;
    if (isFallback) value -= 0.15;

    if (value < 0.4) value = 0.4;
    if (value > 0.98) value = 0.98;
    return ConfidenceAssessment(
      score: value,
      level: confidenceLevelFromSignals(
        hasAmount: hasAmount,
        hasMerchant: hasMerchant,
        hasPatternMatch: hasPatternMatch,
      ),
    );
  }

  static double score({
    required bool hasAmount,
    required bool hasMerchant,
    required bool hasSourceHint,
    required bool hasPatternMatch,
    required bool hasDate,
    required bool isFallback,
  }) {
    return assess(
      hasAmount: hasAmount,
      hasMerchant: hasMerchant,
      hasSourceHint: hasSourceHint,
      hasPatternMatch: hasPatternMatch,
      hasDate: hasDate,
      isFallback: isFallback,
    ).score;
  }

  static ConfidenceLevel confidenceLevelFromSignals({
    required bool hasAmount,
    required bool hasMerchant,
    required bool hasPatternMatch,
  }) {
    if (!hasAmount) return ConfidenceLevel.low;
    if (hasMerchant && hasPatternMatch) return ConfidenceLevel.high;
    if (hasPatternMatch) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  static ConfidenceLevel confidenceLevelFromScore(double score) {
    if (score >= 0.82) return ConfidenceLevel.high;
    if (score >= 0.56) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}
