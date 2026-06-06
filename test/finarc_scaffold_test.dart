import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/shared/widgets/finarc/finarc_widgets.dart';

void main() {
  testWidgets('body respects top safe area when no app bar is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 32)),
        child: const MaterialApp(
          home: FinarcScaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: Key('body-child'), width: 20, height: 20),
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key('body-child'))).dy, 32);
  });

  testWidgets('body does not get double top padding when app bar is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(top: 32)),
        child: const MaterialApp(
          home: FinarcScaffold(
            appBar: FinarcAppBar(title: 'Title'),
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: Key('body-child'), width: 20, height: 20),
            ),
          ),
        ),
      ),
    );

    final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
    final childTop = tester.getTopLeft(find.byKey(const Key('body-child'))).dy;
    expect(childTop, appBarBottom);
  });
}
