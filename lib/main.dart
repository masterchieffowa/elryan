import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'core/database/database_helper.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_service.dart';
import 'presentation/screens/auth/login_screen.dart';

// Global providers
final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final authServiceProvider = Provider((ref) => AuthService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database
  await DatabaseHelper.instance.database;

  // Initialize auth service
  final authService = AuthService();
  await authService.initialize();

  runApp(
    const ProviderScope(
      child: RepairShopApp(),
    ),
  );
}

class RepairShopApp extends ConsumerWidget {
  const RepairShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Laptop Repair Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LoginScreen(),
    );
  }
}
