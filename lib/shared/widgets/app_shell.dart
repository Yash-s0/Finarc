import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_mode.dart';
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
  static const double _bottomNavHeight = 60;
  static const double _fabSize = 58;

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
              context.push('/income/add');
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
            radius: 17,
            backgroundColor: AppColors.darkPrimarySoft.withValues(alpha: 0.95),
            child: Icon(icon, size: 17, color: AppColors.darkAccent),
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
      body: Stack(
        children: [
          widget.navigationShell,
          if (AppModeConfig.showModeBadge)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.darkBorder),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  child: Text(
                    AppModeConfig.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: AppShadows.fab,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          height: _fabSize,
          width: _fabSize,
          child: FloatingActionButton(
            onPressed: _openQuickActions,
            backgroundColor: AppColors.darkPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: const BorderSide(color: AppColors.darkAccent, width: 1),
            ),
            child: const Icon(Icons.bolt_rounded, size: 24),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.darkSurfaceLow,
            border: Border(top: BorderSide(color: AppColors.darkBorder)),
          ),
          child: NavigationBar(
            height: _bottomNavHeight,
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
      ),
    );
  }
}
