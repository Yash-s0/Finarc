import 'parser_text_utils.dart';

class MerchantNormalizer {
  static const Map<String, String> _known = {
    'SWIGGY': 'Swiggy',
    'ZOMATO': 'Zomato',
    'AMAZON': 'Amazon',
    'FLIPKART': 'Flipkart',
    'BLINKIT': 'Blinkit',
    'UBER': 'Uber',
    'OLA': 'Ola',
    'DOMINOS': "Domino's",
    'MYNTRA': 'Myntra',
    'MAKEMYTRIP': 'MakeMyTrip',
    'AIRBNB': 'Airbnb',
    'IRCTC': 'IRCTC',
    'BIGBASKET': 'BigBasket',
    'ZEPTO': 'Zepto',
    'AIRTEL': 'Airtel',
    'JIO': 'Jio',
  };

  static final RegExp _noisePattern = RegExp(
    r'\b(UPI|REF|TXN|INFO|AVL\s*BAL|A\/C|CARD|PAYMENT|DEBITED|CREDITED|THAT|FAST|CHECK|BALANCE|TAP|OPEN|LINK|MARK|READ|NOT|YOU|AVOID|CHARGES)\b',
    caseSensitive: false,
  );

  static String normalize(String rawMerchant) {
    if (rawMerchant.trim().isEmpty) return 'Unknown Merchant';

    final upper = rawMerchant.toUpperCase();
    for (final entry in _known.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }

    var cleaned = upper.replaceAll(_noisePattern, ' ');
    cleaned = cleaned.replaceAll(RegExp(r"[^A-Z0-9&' ]"), ' ');
    cleaned = ParserTextUtils.compactSpaces(cleaned);
    if (cleaned.isEmpty) return 'Unknown Merchant';

    return cleaned
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
