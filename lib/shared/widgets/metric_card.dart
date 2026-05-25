import 'package:flutter/material.dart';

import 'finarc/finarc_metric_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trailing,
  });

  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FinarcMetricCard(title: title, value: value, trailing: trailing);
  }
}
