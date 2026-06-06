import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/shared/widgets/finarc/finarc_widgets.dart';

void main() {
  Widget buildHarness({
    required int itemCount,
    required double itemExtentEstimate,
    double maxHeight = 320,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: FinarcContainedList(
            itemCount: itemCount,
            itemExtentEstimate: itemExtentEstimate,
            maxHeight: maxHeight,
            emptyState: const SizedBox(key: Key('empty')),
            itemBuilder: (context, index) => Container(
              key: Key('item-$index'),
              height: itemExtentEstimate,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('embedded list uses zero top padding', (tester) async {
    await tester.pumpWidget(buildHarness(itemCount: 2, itemExtentEstimate: 60));

    final listTop = tester.getTopLeft(find.byType(ListView)).dy;
    final firstItemTop = tester.getTopLeft(find.byKey(const Key('item-0'))).dy;
    expect(firstItemTop, listTop);
  });

  testWidgets('embedded list with few items does not reserve max height', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(itemCount: 2, itemExtentEstimate: 60, maxHeight: 320),
    );

    final containedHeight = tester
        .getSize(find.byType(FinarcContainedList))
        .height;
    expect(containedHeight, lessThan(320));
  });

  testWidgets(
    'embedded list with many items stays scrollable and shows scrollbar',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(itemCount: 12, itemExtentEstimate: 60, maxHeight: 320),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      expect(find.byKey(const Key('item-11')), findsNothing);
    },
  );
}
