import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/categories/presentation/screens/category_management_screen.dart';
import '../../features/home/domain/entities/expense_log.dart';
import '../../features/home/domain/entities/scheduled_transaction.dart';
import '../../features/home/presentation/screens/add_scheduled_transaction_screen.dart';
import '../../features/home/presentation/screens/budget_screen.dart';
import '../../features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import '../../features/home/presentation/screens/weekly_recap_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/expense_log_detail_screen.dart';
import '../../features/home/presentation/screens/expense_logs_csv_screen.dart';
import '../../features/home/presentation/screens/insight_screen.dart';
import '../../features/home/presentation/screens/scheduled_transaction_detail_screen.dart';
import '../../features/home/presentation/screens/scheduled_transactions_screen.dart';
import '../../features/home/presentation/screens/scheduled_transactions_search_screen.dart';
import '../../features/home/presentation/widgets/animated_branch_container.dart';
import '../../features/home/presentation/widgets/scaffold_with_nav_bar.dart';
import '../../features/home/router/profile_router.dart';
import '../../features/onboarding/router/onboarding_router.dart';
import '../../features/settings/presentation/screens/customize_screen.dart';
import '../../features/settings/presentation/screens/expense_reminders_screen.dart';
import '../../features/settings/presentation/screens/notification_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

enum AppRouter {
  onboarding,
  dashboard,
  quickAdd,
  budget,
  insight,
  settings,
  categoryManagement,
  expenseLogsCsv,
  expenseReminders,
  notificationSettings,
  customize,
  profile,
  scheduledTransactions,
  scheduledTransactionsSearch,
  addScheduledTransaction,
  scheduledTransactionDetail,
  expenseLogDetail,
  weeklyRecap;

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
      case AppRouter.insight:
        return '/insight';
      case AppRouter.settings:
        return '/settings';
      case AppRouter.categoryManagement:
        return '/settings/categories';
      case AppRouter.expenseLogsCsv:
        return '/settings/import-export';
      case AppRouter.expenseReminders:
        return '/settings/expense-reminders';
      case AppRouter.notificationSettings:
        return '/settings/notifications';
      case AppRouter.customize:
        return '/settings/customize';
      case AppRouter.profile:
        return '/profile';
      case AppRouter.scheduledTransactions:
        return '/scheduled-transactions';
      case AppRouter.scheduledTransactionsSearch:
        return '/scheduled-transactions/search';
      case AppRouter.addScheduledTransaction:
        return '/scheduled-transactions/add';
      case AppRouter.scheduledTransactionDetail:
        return '/scheduled-transactions/:id';
      case AppRouter.expenseLogDetail:
        return '/logs/:id';
      case AppRouter.weeklyRecap:
        return '/weekly-recap';
    }
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
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
                path: AppRouter.insight.path,
                name: AppRouter.insight.name,
                pageBuilder:
                    (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: const InsightScreen(),
                    ),
              ),
              GoRoute(
                path: '/report',
                redirect: (context, state) => AppRouter.insight.path,
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
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.categoryManagement.path,
        name: AppRouter.categoryManagement.name,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.expenseLogsCsv.path,
        name: AppRouter.expenseLogsCsv.name,
        builder: (context, state) => const ExpenseLogsCsvScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.expenseReminders.path,
        name: AppRouter.expenseReminders.name,
        builder: (context, state) => const ExpenseRemindersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.notificationSettings.path,
        name: AppRouter.notificationSettings.name,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.customize.path,
        name: AppRouter.customize.name,
        builder: (context, state) => const CustomizeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.budget.path,
        name: AppRouter.budget.name,
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
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
        path: '/daily-recap',
        redirect: (context, state) {
          final d =
              state.uri.queryParameters['date'] ?? state.uri.queryParameters['week'];
          if (d != null && d.isNotEmpty) {
            return Uri(
              path: AppRouter.weeklyRecap.path,
              queryParameters: {'week': d},
            ).toString();
          }
          return AppRouter.weeklyRecap.path;
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.weeklyRecap.path,
        name: AppRouter.weeklyRecap.name,
        builder: (context, state) {
          final raw = state.uri.queryParameters['week'];
          final parsed = parseWeeklyRecapDateFromQuery(raw);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final thisMonday = startOfLocalWeekMonday(today);
          final fallback = thisMonday.subtract(const Duration(days: 7));
          return WeeklyRecapScreen(recapWeekAnchor: parsed ?? fallback);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.addScheduledTransaction.path,
        name: AppRouter.addScheduledTransaction.name,
        builder: (context, state) {
          final extra = state.extra;
          final initial = extra is ScheduledTransaction ? extra : null;
          return AddScheduledTransactionScreen(initial: initial);
        },
      ),
      // Search route must come before detail route (more specific routes first)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.scheduledTransactionsSearch.path,
        name: AppRouter.scheduledTransactionsSearch.name,
        builder: (context, state) => const ScheduledTransactionsSearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRouter.scheduledTransactionDetail.path,
        name: AppRouter.scheduledTransactionDetail.name,
        builder: (context, state) {
          final extra = state.extra;
          final item = extra is ScheduledTransaction ? extra : null;
          final id = state.pathParameters['id'] ?? item?.id ?? '';
          final openedFromDueNow =
              state.uri.queryParameters['dueNow'] == '1';
          return ScheduledTransactionDetailScreen(
            scheduledId: id,
            item: item,
            openedFromDueNow: openedFromDueNow,
          );
        },
      ),
      ...profileRouter,
    ],
  );
}
