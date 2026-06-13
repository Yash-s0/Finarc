import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finarc/shared/widgets/finarc/finarc_loading_skeleton.dart';

void main() {
  testWidgets('loading skeleton group renders header and item count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinarcLoadingSkeletonGroup(items: 3, showHeader: true),
        ),
      ),
    );

    expect(find.byType(FinarcLoadingSkeleton), findsNWidgets(4));
  });

  testWidgets('loading skeleton group can omit header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinarcLoadingSkeletonGroup(items: 2, showHeader: false),
        ),
      ),
    );

    expect(find.byType(FinarcLoadingSkeleton), findsNWidgets(2));
  });
}
