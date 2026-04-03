import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_currency.dart';
import '../core/providers/app_providers.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_responsive.dart';
import '../features/auth/presentation/pages/supabase_startup_guard_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  DateTime? _lastBackgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleInactivityLockOnResume();
      return;
    }

    _lastBackgroundedAt = DateTime.now();
  }

  void _handleInactivityLockOnResume() {
    final settingsState = ref.read(settingsProvider);
    final authState = ref.read(authProvider);

    if (!settingsState.inactivityLockEnabled ||
        !settingsState.biometricsEnabled ||
        !authState.isAuthenticated ||
        authState.requiresBiometricUnlockOnStartup) {
      return;
    }

    final lastBackgroundedAt = _lastBackgroundedAt;
    if (lastBackgroundedAt == null) {
      return;
    }

    final timeout = Duration(minutes: settingsState.inactivityTimeoutMinutes);
    final elapsed = DateTime.now().difference(lastBackgroundedAt);
    if (elapsed >= timeout) {
      ref.read(authProvider.notifier).requireBiometricUnlock();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.biometricUnlock,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final themeMode = settingsState.themeMode;
    final bootstrapState = ref.watch(supabaseBootstrapProvider);

    AppColors.setThemeMode(themeMode);
    AppCurrency.setCurrencyCode(settingsState.currencyCode);

    if (bootstrapState.isChecking) {
      return MaterialApp(
        key: const ValueKey<String>('app-bootstrap-loading'),
        title: 'Zorvyn Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        builder: _responsiveBuilder,
      );
    }

    if (!bootstrapState.isReady) {
      return MaterialApp(
        key: const ValueKey<String>('app-supabase-guard'),
        title: 'Zorvyn Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: SupabaseStartupGuardPage(
          message: bootstrapState.error ??
              'Supabase initialization failed. Verify your configuration and retry.',
          onRetry: () {
            return ref.read(supabaseBootstrapProvider.notifier).bootstrap();
          },
        ),
        builder: _responsiveBuilder,
      );
    }

    final router = AppRouter();
    final authState = ref.watch(authProvider);

    if (authState.isInitializing) {
      return MaterialApp(
        key: const ValueKey<String>('app-loading'),
        title: 'Zorvyn Finance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        builder: _responsiveBuilder,
      );
    }

    final shouldGateWithBiometrics = authState.isAuthenticated &&
        settingsState.biometricsEnabled &&
        authState.requiresBiometricUnlockOnStartup;

    final initialRoute = authState.isAuthenticated
        ? (shouldGateWithBiometrics
            ? AppRouter.biometricUnlock
            : AppRouter.home)
        : AppRouter.login;

    return MaterialApp(
      key: ValueKey<String>('app-ready-$initialRoute'),
      title: 'Zorvyn Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: initialRoute,
      onGenerateRoute: router.onGenerateRoute,
      builder: _responsiveBuilder,
    );
  }

  Widget _responsiveBuilder(BuildContext context, Widget? child) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(View.of(context));
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: AppResponsive.textScaler(context),
      ),
      child: ResponsiveContent(child: child),
    );
  }
}
