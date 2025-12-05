import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../presentation/screens/onboarding_screen.dart';

/// Onboarding feature routes
final List<RouteBase> onboardingRouter = [
  GoRoute(
    path: AppRouter.onboarding.path,
    name: AppRouter.onboarding.name,
    builder: (context, state) => const OnboardingScreen(),
  ),
];

