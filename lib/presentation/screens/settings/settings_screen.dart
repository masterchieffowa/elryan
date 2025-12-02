// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/l10n/app_localizations.dart';
import '../../../main.dart'; // For localeProvider, themeModeProvider, authServiceProvider
import '../auth/login_screen.dart';
import '../../../core/database/database_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Setting
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              subtitle: Text(currentLocale.languageCode == 'ar' ? l10n.isArabic ? 'العربية' : 'Arabic' : 'English'),
              trailing: Switch(
                value: currentLocale.languageCode == 'en',
                onChanged: (value) {
                  ref.read(localeProvider.notifier).state =
                      value ? const Locale('en') : const Locale('ar');
                },
              ),
            ),
          ),

          // Theme Setting
          Card(
            child: ListTile(
              leading: Icon(
                currentThemeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: Text(l10n.theme),
              subtitle: Text(
                currentThemeMode == ThemeMode.dark
                    ? l10n.darkMode
                    : l10n.lightMode,
              ),
              trailing: Switch(
                value: currentThemeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).state =
                      value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Security Section
          Text(
            l10n.isArabic ? 'الأمان' : 'Security',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: Text(l10n.changePassword),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showChangePasswordDialog(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // Database Section
          Text(
            l10n.isArabic ? 'قاعدة البيانات' : 'Database',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: Text(l10n.backupDatabase),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _backupDatabase(context),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: Text(l10n.restoreDatabase),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _restoreDatabase(context),
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                decoration: InputDecoration(labelText: l10n.currentPassword),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                decoration: InputDecoration(labelText: l10n.newPassword),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return l10n.fieldRequired;
                  if (value!.length < 6) {
                    return l10n.isArabic
                        ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
                        : 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                decoration: InputDecoration(labelText: l10n.confirmPassword),
                obscureText: true,
                validator: (value) {
                  if (value != newController.text) {
                    return l10n.passwordMismatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = ref.read(authServiceProvider);
        final isCurrentValid = await authService.login(currentController.text);

        if (!isCurrentValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.incorrectPassword),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await authService.setPassword(newController.text);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passwordChanged),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.backupDatabase,
        fileName: 'laptop_repair_backup_$timestamp.db',
      );

      if (outputPath != null) {
        await File(dbPath).copy(outputPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.saveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreDatabase),
        content: Text(
          l10n.isArabic
              ? 'سيتم استبدال قاعدة البيانات الحالية. هل أنت متأكد؟'
              : 'Current database will be replaced. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null) {
        final dbPath = await DatabaseHelper.instance.getDatabasePath();
        await DatabaseHelper.instance.close();

        await File(result.files.single.path!).copy(dbPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isArabic
                  ? 'تم استعادة قاعدة البيانات. يرجى إعادة تشغيل التطبيق'
                  : 'Database restored. Please restart the app'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}