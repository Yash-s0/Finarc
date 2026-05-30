import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class NotificationDiagnosticsUnavailableScreen extends StatelessWidget {
  const NotificationDiagnosticsUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Notification Diagnostics'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinarcStatusBadge(
                  label: 'Diagnostics unavailable in this build',
                  tone: FinarcStatusTone.neutral,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Install personalDebug to access SMS diagnostics and advanced ingestion debug tools.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
