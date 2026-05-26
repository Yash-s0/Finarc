import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../../pending/notifications/notification_providers.dart';
import '../data/release_diagnostics_providers.dart';

class ReleaseChecklistScreen extends ConsumerWidget {
  const ReleaseChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsState = ref.watch(releaseDiagnosticsProvider);
    final ingestionState = ref.watch(realIngestionAvailableProvider);
    final notifPermState = ref.watch(notificationAccessStatusProvider);
    final smsPermState = ref.watch(smsPermissionStatusProvider);

    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Release Checklist'),
      body: diagnosticsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load release checklist: $error')),
        data: (d) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Runtime'),
                  const SizedBox(height: AppSpacing.sm),
                  _line(context, 'DB schema version', '${d.schemaVersion}'),
                  _line(context, 'App mode', d.appMode),
                  _line(
                    context,
                    'Real ingestion available',
                    ingestionState.valueOrNull == true ? 'YES' : 'NO',
                  ),
                  _line(
                    context,
                    'Notification access',
                    notifPermState.valueOrNull == true ? 'GRANTED' : 'DENIED',
                  ),
                  _line(
                    context,
                    'SMS permission',
                    smsPermState.valueOrNull == true ? 'GRANTED' : 'DENIED',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FinarcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinarcSectionHeader(title: 'Major Table Counts'),
                  const SizedBox(height: AppSpacing.sm),
                  _line(context, 'Bank accounts', '${d.bankAccountsCount}'),
                  _line(context, 'Cash wallets', '${d.cashWalletsCount}'),
                  _line(context, 'Credit cards', '${d.creditCardsCount}'),
                  _line(context, 'Transactions', '${d.transactionsCount}'),
                  _line(
                    context,
                    'Pending transactions',
                    '${d.pendingTransactionsCount}',
                  ),
                  _line(context, 'Alerts', '${d.alertsCount}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
