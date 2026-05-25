import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'finarc/finarc_widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _openQuickActions() {
    FinarcBottomSheet.show<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionTile(Icons.remove_circle_outline, 'Add Expense', () {
              Navigator.pop(context);
              context.push('/expenses/add');
            }),
            _actionTile(Icons.add_circle_outline, 'Add Income', () {
              Navigator.pop(context);
              context.push('/expenses/add-income');
            }),
            _actionTile(Icons.credit_card, 'Add Card', () {
              Navigator.pop(context);
              context.push('/cards/add');
            }),
            _actionTile(Icons.group_add_outlined, 'Split Bill', () {
              Navigator.pop(context);
              context.push('/split');
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return FinarcCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkPrimarySoft,
            child: Icon(icon, size: 18, color: AppColors.darkAccent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FinarcScaffold(
      body: widget.navigationShell,
      floatingActionButton: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: AppShadows.fab,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          height: 54,
          width: 54,
          child: FloatingActionButton(
            onPressed: _openQuickActions,
            backgroundColor: AppColors.darkPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Icon(Icons.bolt_rounded, size: 22),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurfaceLow,
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card),
              label: 'Cards',
            ),
            NavigationDestination(
              icon: Icon(Icons.call_split_outlined),
              label: 'Split',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
