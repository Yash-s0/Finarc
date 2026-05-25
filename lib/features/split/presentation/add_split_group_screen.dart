import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/finarc/finarc_widgets.dart';
import '../data/split_providers.dart';

class AddSplitGroupScreen extends ConsumerStatefulWidget {
  const AddSplitGroupScreen({super.key});

  @override
  ConsumerState<AddSplitGroupScreen> createState() =>
      _AddSplitGroupScreenState();
}

class _AddSplitGroupScreenState extends ConsumerState<AddSplitGroupScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _memberName = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _memberName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      appBar: const FinarcAppBar(title: 'Create Group'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinarcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinarcSectionHeader(title: 'Group Details'),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(controller: _name, label: 'Group name'),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _description,
                  label: 'Description (optional)',
                ),
                const SizedBox(height: AppSpacing.sm),
                FinarcTextField(
                  controller: _memberName,
                  label: 'Add member name (optional)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FinarcPrimaryButton(
            onPressed: () async {
              final name = _name.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group name is required')),
                );
                return;
              }
              final groupId = await ref
                  .read(splitActionsProvider)
                  .createGroup(
                    name,
                    description: _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                  );
              final memberName = _memberName.text.trim();
              if (memberName.isNotEmpty) {
                await ref
                    .read(splitActionsProvider)
                    .addMember(groupId, name: memberName);
              }
              if (!context.mounted) return;
              context.go('/split/groups/$groupId');
            },
            icon: Icons.check_circle_outline,
            label: 'Create Group',
          ),
        ],
      ),
    );
  }
}
