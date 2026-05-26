import 'package:finarc/core/router/route_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pathInt returns null for invalid values', () {
    expect(RouteParsers.pathInt({'id': '0'}, 'id'), isNull);
    expect(RouteParsers.pathInt({'id': '-1'}, 'id'), isNull);
    expect(RouteParsers.pathInt({'id': 'abc'}, 'id'), isNull);
  });

  test('pathInt parses positive integer ids', () {
    expect(RouteParsers.pathInt({'id': '12'}, 'id'), 12);
  });

  test('query parsers return safe fallbacks', () {
    expect(RouteParsers.queryInt({'groupId': '22'}, 'groupId'), 22);
    expect(RouteParsers.queryInt({'groupId': 'bad'}, 'groupId'), isNull);
    expect(RouteParsers.queryDouble({'amount': 'bad'}, 'amount'), 0);
    expect(RouteParsers.queryDouble({'amount': '11.2'}, 'amount'), 11.2);
  });
}
