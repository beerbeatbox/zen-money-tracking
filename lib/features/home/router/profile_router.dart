import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../presentation/screens/profile_screen.dart';

/// Profile feature routes
final List<RouteBase> profileRouter = [
  GoRoute(
    path: AppRouter.profile.path,
    name: AppRouter.profile.name,
    builder: (context, state) => const ProfileScreen(),
  ),
];

