enum ConfidenceLevel { high, medium, low }

extension ConfidenceLevelX on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.high:
        return 'HIGH';
      case ConfidenceLevel.medium:
        return 'MEDIUM';
      case ConfidenceLevel.low:
        return 'LOW';
    }
  }
}
