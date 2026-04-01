import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/theme/app_theme.dart' show AppTheme;

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = AppRouter();

    // Determine initial route based on auth status
    String initialRoute;
    if (authState.isLoading) {
      // Show loading screen while checking auth status
      return MaterialApp(
        title: 'Frontend',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else if (authState.isAuthenticated) {
      initialRoute = AppRouter.home;
    } else {
      initialRoute = AppRouter.login;
    }

    return MaterialApp(
        title: 'Frontend',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        onGenerateRoute: router.onGenerateRoute,
      );
  }
}

