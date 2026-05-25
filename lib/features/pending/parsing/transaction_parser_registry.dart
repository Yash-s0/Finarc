import 'parser_models.dart';
import 'parsers/generic_fallback_parser.dart';
import 'transaction_parser.dart';

class TransactionParserRegistry {
  TransactionParserRegistry({
    List<TransactionParser>? parsers,
    TransactionParser? fallbackParser,
  }) : _fallbackParser = fallbackParser ?? GenericFallbackParser() {
    if (parsers != null) {
      _parsers.addAll(parsers);
    }
  }

  final List<TransactionParser> _parsers = [];
  final TransactionParser _fallbackParser;

  void register(TransactionParser parser) {
    _parsers.add(parser);
  }

  ParserResult parseInput(ParserInput input) {
    ParserResult? best;
    var bestConfidence = -1.0;

    for (final parser in _parsers) {
      if (!parser.canParse(input)) continue;
      final result = parser.parse(input);
      if (result.candidates.isEmpty) continue;

      final maxConfidence = result.candidates
          .map((c) => c.confidenceScore)
          .reduce((a, b) => a > b ? a : b);

      if (maxConfidence > bestConfidence) {
        best = result;
        bestConfidence = maxConfidence;
      }
    }

    if (best != null) return best;

    final fallback = _fallbackParser.parse(input);
    if (fallback.candidates.isNotEmpty) return fallback;

    return ParserResult(
      candidates: const [],
      warnings: const ['No parser could derive transaction candidates'],
      parserName: _fallbackParser.parserName,
      parsedAt: DateTime.now(),
    );
  }
}
