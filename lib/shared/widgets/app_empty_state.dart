import 'package:flutter/material.dart';

import 'finarc/finarc_empty_state.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FinarcEmptyState(title: title, subtitle: subtitle, icon: icon);
  }
}
