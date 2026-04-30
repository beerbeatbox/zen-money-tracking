// Basic smoke test for app bootstrapping.

import 'package:baht/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    app.appConfig = app.AppConfig(
      environment: app.Environment.dev,
      apiBaseUrl: 'https://example.invalid',
      appTitle: 'Test',
    );

    await tester.pumpWidget(const ProviderScope(child: app.MyApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
