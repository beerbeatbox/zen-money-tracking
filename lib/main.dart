import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'features/settings/domain/usecases/settings_service.dart';

enum Environment { dev, sit, uat, prod }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String appTitle;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appTitle,
  });
}

late AppConfig appConfig;

void mainCommon(AppConfig config) {
  appConfig = config;
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service and reschedule reminders after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Get saved reminders and reschedule them
    final settingsService = ref.read(settingsServiceProvider);
    final reminders = await settingsService.getExpenseReminders();
    await notificationService.rescheduleAllReminders(reminders);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: appConfig.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
