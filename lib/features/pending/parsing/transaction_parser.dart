import 'parser_models.dart';

abstract class TransactionParser {
  String get parserName;

  bool canParse(ParserInput input);

  ParserResult parse(ParserInput input);
}
