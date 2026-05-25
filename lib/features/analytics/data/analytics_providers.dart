import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../cards/data/cards_providers.dart';
import '../../loans/data/loans_providers.dart';
import '../../split/data/split_providers.dart';
import 'analytics_models.dart';
import 'analytics_service.dart';

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (ref) => AnalyticsPeriod.thisMonth,
);

final analyticsCustomRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    ref.read(appDatabaseProvider),
    ref.read(billingServiceProvider),
    ref.read(loanServiceProvider),
    ref.read(splitServiceProvider),
  );
});

final analyticsSnapshotProvider = FutureProvider<AnalyticsSnapshot>((
  ref,
) async {
  await ref.watch(seedProvider.future);
  final period = ref.watch(analyticsPeriodProvider);
  final custom = ref.watch(analyticsCustomRangeProvider);
  return ref
      .read(analyticsServiceProvider)
      .buildSnapshot(period: period, customRange: custom);
});
