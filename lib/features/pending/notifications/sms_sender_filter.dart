class SmsSenderFilterResult {
  const SmsSenderFilterResult({required this.accepted, required this.reason});

  final bool accepted;
  final String reason;
}

class SmsSenderFilter {
  const SmsSenderFilter();

  SmsSenderFilterResult evaluate(String? sender) {
    final normalized = _normalize(sender);
    if (normalized.isEmpty) {
      return const SmsSenderFilterResult(
        accepted: false,
        reason: 'blocked-unknown-sender',
      );
    }

    if (_looksLikePhoneNumber(normalized)) {
      return const SmsSenderFilterResult(
        accepted: false,
        reason: 'blocked-unknown-sender',
      );
    }

    if (normalized.endsWith('-P')) {
      return const SmsSenderFilterResult(
        accepted: false,
        reason: 'blocked-promotional-sender',
      );
    }

    if (normalized.endsWith('-T') || normalized.endsWith('-S')) {
      return const SmsSenderFilterResult(
        accepted: true,
        reason: 'allowed-transactional-sender',
      );
    }

    return const SmsSenderFilterResult(
      accepted: false,
      reason: 'blocked-unknown-sender',
    );
  }

  String _normalize(String? sender) {
    return (sender ?? '').trim().toUpperCase();
  }

  bool _looksLikePhoneNumber(String sender) {
    final compact = sender.replaceAll(RegExp(r'[^0-9+]'), '');
    final digits = compact.replaceAll('+', '');
    return digits.length >= 10 && RegExp(r'^\+?[0-9]+$').hasMatch(compact);
  }
}
