import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/home/presentation/widgets/scaffold_with_nav_bar.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/router/profile_router.dart';
import '../../features/onboarding/router/onboarding_router.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

enum AppRouter {
  onboarding,
  dashboard,
  settings,
  profile;

  String get path {
    switch (this) {
      case AppRouter.onboarding:
        return '/onboarding';
      case AppRouter.dashboard:
        return '/dashboard';
      case AppRouter.settings:
        return '/settings';
      case AppRouter.profile:
        return '/profile';
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
    initialLocation: AppRouter.onboarding.path,
    routes: [
      ...onboardingRouter,
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: AppRouter.dashboard.path,
            name: AppRouter.dashboard.name,
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRouter.settings.path,
            name: AppRouter.settings.name,
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      ...profileRouter,
    ],
  );
}
