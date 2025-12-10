// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elryan/main.dart';

void main() {
  testWidgets('ELRYAN app launches and shows login screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RepairShopApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that login screen is shown
    expect(find.text('الريان'), findsOneWidget); // App name in Arabic
    expect(find.text('ELRAYAN'), findsOneWidget); // App name in English

    // Verify password field exists
    expect(find.byType(TextFormField), findsWidgets);

    // Verify login button exists
    expect(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'),
        findsOneWidget); // Login in Arabic
  });

  testWidgets('Login screen has password field and login button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RepairShopApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find password field
    final passwordField = find.byType(TextFormField);
    expect(passwordField, findsOneWidget);

    // Find login button
    final loginButton = find.byType(ElevatedButton);
    expect(loginButton, findsOneWidget);
  });

  testWidgets('App has proper localization support',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RepairShopApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify MaterialApp is properly configured
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.supportedLocales, contains(const Locale('ar')));
    expect(materialApp.supportedLocales, contains(const Locale('en')));
  });
}
