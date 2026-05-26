import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/alerts/presentation/alerts_center_screen.dart';
import '../../features/cards/presentation/add_card_screen.dart';
import '../../features/cards/presentation/bill_detail_screen.dart';
import '../../features/cards/presentation/card_detail_screen.dart';
import '../../features/cards/presentation/cards_overview_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/net_worth_breakdown_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/expenses/presentation/add_expense_screen.dart';
import '../../features/expenses/presentation/add_income_screen.dart';
import '../../features/expenses/presentation/transaction_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/split/presentation/split_screen.dart';
import '../../features/split/presentation/add_split_group_screen.dart';
import '../../features/split/presentation/split_group_detail_screen.dart';
import '../../features/split/presentation/add_split_expense_screen.dart';
import '../../features/split/presentation/split_balance_detail_screen.dart';
import '../../features/split/presentation/add_split_settlement_screen.dart';
import '../../features/split/presentation/split_settlement_success_screen.dart';
import '../../features/pending/presentation/cashback_screen.dart';
import '../../features/pending/presentation/edit_pending_transaction_screen.dart';
import '../../features/pending/presentation/for_others_screen.dart';
import '../../features/pending/presentation/pending_success_screen.dart';
import '../../features/pending/presentation/pending_transactions_screen.dart';
import '../../features/pending/notifications/notification_access_setup_screen.dart';
import '../../features/pending/notifications/sms_access_setup_screen.dart';
import '../../features/onboarding/presentation/onboarding_flow_screen.dart';
import '../../features/accounts/presentation/account_detail_screen.dart';
import '../../features/accounts/presentation/accounts_overview_screen.dart';
import '../../features/accounts/presentation/add_edit_account_screen.dart';
import '../../features/accounts/presentation/reconcile_screen.dart';
import '../../features/accounts/presentation/transfer_screen.dart';
import '../../features/accounts/presentation/transfer_success_screen.dart';
import '../../features/loans/presentation/add_edit_loan_screen.dart';
import '../../features/loans/presentation/emi_payment_screen.dart';
import '../../features/loans/presentation/loan_detail_screen.dart';
import '../../features/loans/presentation/loans_dashboard_screen.dart';
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (_, _) => const ExpensesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cards',
              builder: (_, _) => const CardsOverviewScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/split', builder: (_, _) => const SplitScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        ),
      ],
    ),
    GoRoute(path: '/cards/add', builder: (_, _) => const AddCardScreen()),
    GoRoute(
      path: '/cards/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return CardDetailScreen(cardId: id);
      },
    ),
    GoRoute(
      path: '/cards/:cardId/bills/:billId',
      builder: (_, state) {
        final cardId = int.tryParse(state.pathParameters['cardId'] ?? '') ?? 0;
        final billId = int.tryParse(state.pathParameters['billId'] ?? '') ?? 0;
        return BillDetailScreen(cardId: cardId, billId: billId);
      },
    ),
    GoRoute(path: '/expenses/add', builder: (_, _) => const AddExpenseScreen()),
    GoRoute(
      path: '/expenses/transaction/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TransactionDetailScreen(transactionId: id);
      },
    ),
    GoRoute(path: '/income/add', builder: (_, _) => const AddIncomeScreen()),
    GoRoute(
      path: '/pending',
      builder: (_, state) {
        final openPendingId = int.tryParse(
          state.uri.queryParameters['openPendingId'] ?? '',
        );
        return PendingTransactionsScreen(openPendingId: openPendingId);
      },
    ),
    GoRoute(
      path: '/notifications/setup',
      builder: (_, _) => const NotificationAccessSetupScreen(),
    ),
    GoRoute(
      path: '/sms/setup',
      builder: (_, _) => const SmsAccessSetupScreen(),
    ),
    GoRoute(
      path: '/pending/edit/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EditPendingTransactionScreen(pendingId: id);
      },
    ),
    GoRoute(
      path: '/pending/for-others/:id',
      builder: (_, _) => const ForOthersScreen(),
    ),
    GoRoute(
      path: '/pending/cashback/:id',
      builder: (_, _) => const CashbackScreen(),
    ),
    GoRoute(
      path: '/pending/success',
      builder: (_, _) => const PendingSuccessScreen(),
    ),
    GoRoute(
      path: '/accounts',
      builder: (_, _) => const AccountsOverviewScreen(),
    ),
    GoRoute(
      path: '/accounts/add',
      builder: (_, state) {
        final type = state.uri.queryParameters['type'];
        return AddEditAccountScreen(initialType: type);
      },
    ),
    GoRoute(
      path: '/accounts/transfer',
      builder: (_, _) => const TransferScreen(),
    ),
    GoRoute(
      path: '/accounts/transfer/success',
      builder: (_, state) {
        final amount =
            double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final from = state.uri.queryParameters['from'] ?? 'bank';
        final to = state.uri.queryParameters['to'] ?? 'cash';
        return TransferSuccessScreen(
          amount: amount,
          fromType: from,
          toType: to,
        );
      },
    ),
    GoRoute(
      path: '/accounts/detail/:type/:id',
      builder: (_, state) {
        final type = state.pathParameters['type'] ?? 'bank';
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AccountDetailScreen(type: type, id: id);
      },
    ),
    GoRoute(
      path: '/accounts/reconcile/:type/:id',
      builder: (_, state) {
        final type = state.pathParameters['type'] ?? 'bank';
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ReconcileScreen(type: type, id: id);
      },
    ),
    GoRoute(path: '/loans', builder: (_, _) => const LoansDashboardScreen()),
    GoRoute(path: '/loans/add', builder: (_, _) => const AddEditLoanScreen()),
    GoRoute(
      path: '/loans/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return LoanDetailScreen(loanId: id);
      },
    ),
    GoRoute(
      path: '/loans/:id/edit',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AddEditLoanScreen(loanId: id);
      },
    ),
    GoRoute(
      path: '/loans/:id/pay',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EmiPaymentScreen(loanId: id);
      },
    ),
    GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsScreen()),
    GoRoute(
      path: '/dashboard/net-worth-breakdown',
      builder: (_, _) => const NetWorthBreakdownScreen(),
    ),
    GoRoute(path: '/alerts', builder: (_, _) => const AlertsCenterScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (_, _) => const OnboardingFlowScreen(),
    ),
    GoRoute(
      path: '/split/groups/add',
      builder: (_, _) => const AddSplitGroupScreen(),
    ),
    GoRoute(
      path: '/split/groups/:groupId',
      builder: (_, state) {
        final groupId =
            int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
        return SplitGroupDetailScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/split/groups/:groupId/add-expense',
      builder: (_, state) {
        final groupId =
            int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
        return AddSplitExpenseScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/split/groups/:groupId/balances',
      builder: (_, state) {
        final groupId =
            int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
        return SplitBalanceDetailScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/split/groups/:groupId/settle',
      builder: (_, state) {
        final groupId =
            int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
        return AddSplitSettlementScreen(groupId: groupId);
      },
    ),
    GoRoute(
      path: '/split/settlement/success',
      builder: (_, state) {
        final amount =
            double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0;
        final groupId =
            int.tryParse(state.uri.queryParameters['groupId'] ?? '') ?? 0;
        return SplitSettlementSuccessScreen(amount: amount, groupId: groupId);
      },
    ),
  ],
);
