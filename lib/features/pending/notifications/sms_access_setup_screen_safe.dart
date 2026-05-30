import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class SmsAccessSetupScreenSafe extends StatelessWidget {
  const SmsAccessSetupScreenSafe({super.key});

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'SMS Access'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FinarcStatusBadge(
                  label: 'SMS NOT AVAILABLE IN THIS BUILD',
                  tone: FinarcStatusTone.neutral,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'SMS reading is not included in this Play-safe release build.',
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Notification listener ingestion remains available for local pending detection.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
