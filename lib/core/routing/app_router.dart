import 'package:flutter/material.dart';

import '../../features/finance/presentation/pages/finance_shell_page.dart';
import '../../features/auth/presentation/pages/email_verification_pending_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import 'route_guard.dart';

class AppRouter {
  static const home = '/';
  static const settings = '/settings';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';

  Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const FinanceShellPage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case verifyEmail:
        final emailArg = routeSettings.arguments;
        final email = emailArg is String ? emailArg : '';
        return MaterialPageRoute(
          builder: (_) => EmailVerificationPendingPage(email: email),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      default:
        return MaterialPageRoute(builder: (_) => const FinanceShellPage());
    }
  }

  Route<dynamic> guarded({
    required RouteSettings routeSettings,
    required RouteGuard guard,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute(
      settings: routeSettings,
      builder: (context) {
        if (!guard.canActivate(routeSettings)) {
          return guard.fallback(context: context);
        }
        return builder(context);
      },
    );
  }
}
