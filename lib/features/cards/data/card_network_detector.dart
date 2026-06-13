import 'cards_providers.dart';

/// Detects the card network from the first 6–8 digits (BIN/IIN) of a card
/// number.
///
/// Returns one of [CardNetwork.visa], [CardNetwork.mastercard],
/// [CardNetwork.rupay], [CardNetwork.amex], or `null` if the BIN is too
/// short, non-numeric, or doesn't match a known range.
///
/// The BIN is never stored — it is used only at add-time to pre-fill the
/// network dropdown.
String? detectCardNetwork(String binPrefix) {
  final cleaned = binPrefix.trim();
  if (cleaned.length < 6) return null;
  if (int.tryParse(cleaned) == null) return null;

  final bin4 = int.parse(cleaned.substring(0, 4));
  final bin3 = int.parse(cleaned.substring(0, 3));
  final bin2 = int.parse(cleaned.substring(0, 2));

  // ── Amex: starts with 34 or 37 ──────────────────────────────────────
  if (bin2 == 34 || bin2 == 37) return CardNetwork.amex;

  // ── RuPay: Broader prefix matching for Indian context ────────────────
  if (bin3 == 508 ||
      _inRange(bin3, 606, 608) ||
      _inRange(bin3, 652, 653) ||
      _inRange(bin2, 81, 82) ||
      bin3 == 353 ||
      bin3 == 356) {
    return CardNetwork.rupay;
  }

  // ── Mastercard: 51–55 or 2221–2720 ──────────────────────────────────
  if (_inRange(bin2, 51, 55) || _inRange(bin4, 2221, 2720)) {
    return CardNetwork.mastercard;
  }

  // ── Visa: starts with 4 ─────────────────────────────────────────────
  if (cleaned.startsWith('4')) return CardNetwork.visa;

  return null;
}

bool _inRange(int value, int low, int high) => value >= low && value <= high;
