import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_currency.dart';
import '../../../../core/providers/app_providers.dart';
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
              SettingsTile(
                icon: Icons.currency_exchange_rounded,
                title: 'Currency',
                subtitle: _getCurrencyName(settingsState.currencyCode),
                onTap: () => _showCurrencyDialog(context, ref),
              ),
              SettingsTile(
                icon: Icons.animation_rounded,
                title: 'Reduce Motion',
                subtitle:
                    settingsState.reduceMotionEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: settingsState.reduceMotionEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setReduceMotionEnabled(value);
                  },
                ),
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
                  onChanged: (value) async {
                    await _toggleBiometrics(context, ref, value);
                  },
                ),
              ),
              SettingsTile(
                icon: Icons.lock_clock_outlined,
                title: 'Inactivity Auto-Lock',
                subtitle: settingsState.inactivityLockEnabled
                    ? 'After ${settingsState.inactivityTimeoutMinutes} min'
                    : 'Disabled',
                trailing: Switch(
                  value: settingsState.inactivityLockEnabled,
                  onChanged: (value) async {
                    if (!value) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setInactivityLockEnabled(false);
                      return;
                    }

                    final hasBiometric =
                        ref.read(settingsProvider).biometricsEnabled;
                    if (!hasBiometric) {
                      final enabled =
                          await _toggleBiometrics(context, ref, true);
                      if (!enabled || !context.mounted) {
                        return;
                      }
                    }

                    await ref
                        .read(settingsProvider.notifier)
                        .setInactivityLockEnabled(true);
                  },
                ),
              ),
              SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Auto-Lock Timeout',
                subtitle: settingsState.inactivityLockEnabled
                    ? '${settingsState.inactivityTimeoutMinutes} minutes'
                    : 'Enable inactivity lock first',
                onTap: settingsState.inactivityLockEnabled
                    ? () => _showInactivityTimeoutDialog(context, ref)
                    : null,
              ),
              SettingsTile(
                icon: Icons.lock_person_outlined,
                title: 'Lock Now',
                subtitle: 'Require biometric unlock immediately',
                onTap: () => _lockNow(context, ref),
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
              SettingsTile(
                icon: Icons.devices_other_rounded,
                title: 'Logout All Devices',
                subtitle: 'End active sessions on every device',
                onTap: () => _showLogoutDialogWithScope(
                  context,
                  ref,
                  allSessions: true,
                ),
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

  String _getCurrencyName(String code) {
    return '${AppCurrency.nameFor(code)} ($code)';
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

  void _showCurrencyDialog(BuildContext context, WidgetRef ref) {
    final currentCurrencyCode = ref.read(settingsProvider).currencyCode;
    final options = AppCurrency.supportedCodes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Choose Currency'),
        content: RadioGroup<String>(
          groupValue: currentCurrencyCode,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref.read(settingsProvider.notifier).setCurrencyCode(value);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (code) => RadioListTile<String>(
                    title: Text('${AppCurrency.nameFor(code)} ($code)'),
                    value: code,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showInactivityTimeoutDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).inactivityTimeoutMinutes;
    const options = <int>[1, 2, 5, 10, 15, 30, 60, 120];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: const Text('Auto-lock timeout'),
        content: RadioGroup<int>(
          groupValue: current,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref.read(settingsProvider.notifier).setInactivityTimeoutMinutes(
                  value,
                );
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (minutes) => RadioListTile<int>(
                    title: Text('$minutes minutes'),
                    value: minutes,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<bool> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    if (!enabled) {
      await settingsNotifier.setBiometricsEnabled(false);
      return true;
    }

    final biometricService = ref.read(biometricAuthServiceProvider);
    final availability = await biometricService.checkAvailability();

    if (!availability.isAvailable) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availability.message ??
                'Biometric authentication is unavailable on this device.',
          ),
        ),
      );
      return false;
    }

    final result = await biometricService.authenticate(
      reason: 'Confirm biometric unlock for app startup',
    );

    if (!result.isAuthenticated) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Biometric verification failed. Setting was not enabled.',
          ),
        ),
      );
      return false;
    }

    await settingsNotifier.setBiometricsEnabled(true);
    if (!context.mounted) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biometric login enabled for app startup.'),
      ),
    );

    return true;
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
    _showLogoutDialogWithScope(context, ref, allSessions: false);
  }

  Future<void> _lockNow(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to lock now.')),
        );
      }
      return;
    }

    final settingsState = ref.read(settingsProvider);
    if (!settingsState.biometricsEnabled) {
      final enabled = await _toggleBiometrics(context, ref, true);
      if (!enabled || !context.mounted) {
        return;
      }
    }

    ref.read(authProvider.notifier).requireBiometricUnlock();
    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.biometricUnlock,
      (route) => false,
    );
  }

  void _showLogoutDialogWithScope(
    BuildContext context,
    WidgetRef ref, {
    required bool allSessions,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape(context),
        title: Text(allSessions ? 'Logout Everywhere?' : 'Logout?'),
        content: Text(
          allSessions
              ? 'This will sign you out from all devices.'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(authProvider.notifier).logout(
                    allSessions: allSessions,
                  );

              if (!context.mounted) {
                return;
              }

              if (success) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
                return;
              }

              final message = ref.read(authProvider).error ??
                  (allSessions
                      ? 'Unable to logout all devices right now. Please try again.'
                      : 'Unable to logout right now. Please try again.');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            child: Text(allSessions ? 'Logout all' : 'Logout'),
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
