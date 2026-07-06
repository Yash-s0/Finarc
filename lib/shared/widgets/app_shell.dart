import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_mode.dart';
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
  static const double _fabSize = 50;
  static const double _fabBottomPad = 12; // ~0.5cm-ish gap above nav
  static const double _homeBodyBottomInset = 0;

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
            _actionTile(Icons.fact_check_outlined, 'Pending Transactions', () {
              Navigator.pop(context);
              context.push('/pending');
            }),
            _actionTile(
              Icons.text_snippet_outlined,
              'Paste Missed Message',
              () {
                Navigator.pop(context);
                context.push('/pending/paste');
              },
            ),
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
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              icon,
              size: 17,
              color: Theme.of(context).colorScheme.primary,
            ),
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
    final isHomeTab = widget.navigationShell.currentIndex == 0;
    return FinarcScaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: isHomeTab ? _homeBodyBottomInset : 0,
            ),
            child: widget.navigationShell,
          ),
          if (AppModeConfig.showModeBadge)
            Positioned(
              top: 8,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.fromBorderSide(
                    BorderSide(color: Theme.of(context).dividerColor),
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
      floatingActionButton: isHomeTab
          ? DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: AppShadows.fab,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 2, bottom: _fabBottomPad),
                child: SizedBox(
                  height: _fabSize,
                  width: _fabSize,
                  child: FloatingActionButton(
                    onPressed: _openQuickActions,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).navigationBarTheme.backgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
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
      ),
    );
  }
}
