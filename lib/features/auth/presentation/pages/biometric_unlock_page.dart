import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/auth_provider.dart';

class BiometricUnlockPage extends ConsumerStatefulWidget {
  const BiometricUnlockPage({super.key});

  @override
  ConsumerState<BiometricUnlockPage> createState() =>
      _BiometricUnlockPageState();
}

class _BiometricUnlockPageState extends ConsumerState<BiometricUnlockPage> {
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) {
      return;
    }

    final isEnabled = ref.read(settingsProvider).biometricsEnabled;
    if (!isEnabled) {
      if (!mounted) {
        return;
      }
      ref.read(authProvider.notifier).markStartupBiometricSatisfied();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    final biometricService = ref.read(biometricAuthServiceProvider);
    final availability = await biometricService.checkAvailability();
    if (!availability.isAvailable) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAuthenticating = false;
        _error = availability.message;
      });
      return;
    }

    final result = await biometricService.authenticate(
      reason: 'Authenticate to unlock your finance dashboard',
    );

    if (!mounted) {
      return;
    }

    if (result.isAuthenticated) {
      ref.read(authProvider.notifier).markStartupBiometricSatisfied();
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.home,
        (route) => false,
      );
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _error = result.message;
    });
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.rs(24)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.rValue(
                  mobile: double.infinity,
                  tablet: 480,
                  desktop: 520,
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(context.rs(22)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(context.rRadius(28)),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.22),
                    width: context.rThickness(1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: context.rs(72),
                      height: context.rs(72),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(context.rRadius(22)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fingerprint,
                        size: context.rIcon(36),
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: context.rs(18)),
                    Text(
                      'Biometric Unlock',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: context.rs(8)),
                    Text(
                      'Use your fingerprint or face ID to continue.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      SizedBox(height: context.rs(14)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(context.rs(12)),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(context.rRadius(14)),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                            width: context.rThickness(1),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    SizedBox(height: context.rs(18)),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isAuthenticating ? null : _authenticate,
                        icon: _isAuthenticating
                            ? SizedBox(
                                width: context.rs(16),
                                height: context.rs(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: context.rThickness(2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.onPrimary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.lock_open_rounded,
                                size: context.rIcon(18),
                              ),
                        label: Text(
                          _isAuthenticating
                              ? 'Authenticating...'
                              : 'Unlock App',
                        ),
                      ),
                    ),
                    SizedBox(height: context.rs(8)),
                    TextButton(
                      onPressed: _isAuthenticating ? null : _logout,
                      child: const Text('Logout instead'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
