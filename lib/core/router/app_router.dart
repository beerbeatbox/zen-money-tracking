import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/categories/presentation/screens/category_management_screen.dart';
import '../../features/home/domain/entities/expense_log.dart';
import '../../features/home/domain/entities/scheduled_transaction.dart';
import '../../features/home/presentation/screens/add_scheduled_transaction_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/expense_log_detail_screen.dart';
import '../../features/home/presentation/screens/report_screen.dart';
import '../../features/home/presentation/screens/scheduled_transaction_detail_screen.dart';
import '../../features/home/presentation/screens/scheduled_transactions_screen.dart';
import '../../features/home/presentation/widgets/scaffold_with_nav_bar.dart';
import '../../features/home/router/profile_router.dart';
import '../../features/onboarding/router/onboarding_router.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

enum AppRouter {
  onboarding,
  dashboard,
  quickAdd,
  budget,
  report,
  settings,
  categoryManagement,
  profile,
  scheduledTransactions,
  addScheduledTransaction,
  scheduledTransactionDetail,
  expenseLogDetail;

  String get path {
    switch (this) {
      case AppRouter.onboarding:
        return '/onboarding';
      case AppRouter.dashboard:
        return '/dashboard';
      case AppRouter.quickAdd:
        return '/quick-add';
      case AppRouter.budget:
        return '/budget';
      case AppRouter.report:
        return '/report';
      case AppRouter.settings:
        return '/settings';
      case AppRouter.categoryManagement:
        return '/settings/categories';
      case AppRouter.profile:
        return '/profile';
      case AppRouter.scheduledTransactions:
        return '/scheduled-transactions';
      case AppRouter.addScheduledTransaction:
        return '/scheduled-transactions/add';
      case AppRouter.scheduledTransactionDetail:
        return '/scheduled-transactions/:id';
      case AppRouter.expenseLogDetail:
        return '/logs/:id';
    }
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: AppRouter.dashboard.path,
    routes: [
      ...onboardingRouter,
      GoRoute(
        path: AppRouter.quickAdd.path,
        name: AppRouter.quickAdd.name,
        redirect: (context, state) {
          final qp = <String, String>{...state.uri.queryParameters};
          qp['quickAdd'] = '1';
          return Uri(
            path: AppRouter.dashboard.path,
            queryParameters: qp,
          ).toString();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRouter.dashboard.path,
                name: AppRouter.dashboard.name,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey, // keep unique per branch root
                      child: const DashboardScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.report.path,
                name: AppRouter.report.name,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const ReportScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.scheduledTransactions.path,
                name: AppRouter.scheduledTransactions.name,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const ScheduledTransactionsScreen(),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.settings.path,
                name: AppRouter.settings.name,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const SettingsScreen(),
                    ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRouter.categoryManagement.path,
        name: AppRouter.categoryManagement.name,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRouter.expenseLogDetail.path,
        name: AppRouter.expenseLogDetail.name,
        builder: (context, state) {
          final extra = state.extra;
          final log = extra is ExpenseLog ? extra : null;
          final logId = state.pathParameters['id'] ?? log?.id ?? '';
          return ExpenseLogDetailScreen(logId: logId, log: log);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRouter.addScheduledTransaction.path,
        name: AppRouter.addScheduledTransaction.name,
        builder: (context, state) {
          final extra = state.extra;
          final initial = extra is ScheduledTransaction ? extra : null;
          return AddScheduledTransactionScreen(initial: initial);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRouter.scheduledTransactionDetail.path,
        name: AppRouter.scheduledTransactionDetail.name,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra is ScheduledTransaction ? extra : null;
          final id = state.pathParameters['id'] ?? item?.id ?? '';
          return ScheduledTransactionDetailScreen(scheduledId: id, item: item);
        },
      ),
      ...profileRouter,
    ],
  );
}
