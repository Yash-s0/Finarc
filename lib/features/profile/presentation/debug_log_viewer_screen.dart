import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logging_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';

class DebugLogViewerScreen extends ConsumerWidget {
  const DebugLogViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(appDiskLogsProvider);
    return FinarcScaffold(
      appBar: FinarcAppBar(
        title: 'Debug Logs',
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref.read(appLogServiceProvider).clear();
              ref.invalidate(appDiskLogsProvider);
            },
          ),
        ],
      ),
      body: logsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load logs: $error')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: FinarcEmptyState(
                title: 'No logs yet',
                subtitle: 'Local debug logs will appear here.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (context, index) {
              final entry = logs[index];
              return FinarcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.category.toUpperCase()}  ${entry.timestamp.toIso8601String()}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(entry.message),
                    if (entry.meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        entry.meta.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemCount: logs.length,
          );
        },
      ),
    );
  }
}
