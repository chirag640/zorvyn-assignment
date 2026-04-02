import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: context.rs(4),
          bottom: context.rs(24),
        ),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: _getThemeName(settingsState.themeMode),
                onTap: () => _showThemeDialog(context, ref),
              ),
              SettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _getLanguageName(settingsState.language),
                onTap: () => _showLanguageDialog(context, ref),
              ),
            ],
          ),
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle:
                    settingsState.notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: settingsState.notificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setNotificationsEnabled(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Security',
            children: [
              SettingsTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle:
                    settingsState.biometricsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: settingsState.biometricsEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setBiometricsEnabled(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'View and edit your profile',
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.profile);
                },
              ),
              SettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  _showInfoDocumentDialog(
                    context,
                    title: 'Terms of Service',
                    lines: const [
                      'Use this app for personal budgeting and expense tracking only.',
                      'Data is stored locally on this device for assignment/demo scope.',
                      'You are responsible for entered financial data accuracy.',
                    ],
                  );
                },
              ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  _showInfoDocumentDialog(
                    context,
                    title: 'Privacy Policy',
                    lines: const [
                      'No third-party analytics or cloud sync is enabled in this demo build.',
                      'Your settings and finance records are persisted locally.',
                      'Clearing app data removes stored local information.',
                    ],
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Danger Zone',
            children: [
              SettingsTile(
                icon: Icons.delete_outline,
                title: 'Clear All Data',
                subtitle: 'Remove all cached data',
                titleColor: Theme.of(context).colorScheme.error,
                onTap: () => _showClearDataDialog(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi';
      case 'es':
        return 'Spanish';
      default:
        return 'English';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(settingsProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Choose Theme'),
        content: RadioGroup<ThemeMode>(
          groupValue: currentTheme,
          onChanged: (value) {
            if (value != null) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(settingsProvider).language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Choose Language'),
        content: RadioGroup<String>(
          groupValue: currentLanguage,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref.read(settingsProvider.notifier).setLanguage(value);
            Navigator.pop(context);
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('English'),
                value: 'en',
              ),
              RadioListTile<String>(
                title: Text('Hindi'),
                value: 'hi',
              ),
              RadioListTile<String>(
                title: Text('Spanish'),
                value: 'es',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDocumentDialog(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map(
                (line) => Padding(
                  padding: EdgeInsets.only(bottom: context.rs(8)),
                  child: Text(line),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all cached data and reset the app to its initial state. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  ShapeBorder _dialogShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.rRadius(24)),
    );
  }
}
