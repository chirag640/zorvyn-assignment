import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_responsive.dart';
import '../features/auth/presentation/pages/supabase_startup_guard_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    final bootstrapState = ref.watch(supabaseBootstrapProvider);

    if (bootstrapState.isChecking) {
      return MaterialApp(
        key: const ValueKey<String>('app-bootstrap-loading'),
        title: 'Premium Playful Finance',
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
        title: 'Premium Playful Finance',
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
        title: 'Premium Playful Finance',
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

    final initialRoute =
        authState.isAuthenticated ? AppRouter.home : AppRouter.login;

    return MaterialApp(
      key: ValueKey<String>('app-ready-$initialRoute'),
      title: 'Premium Playful Finance',
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
