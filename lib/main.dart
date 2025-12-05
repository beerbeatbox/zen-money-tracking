import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
