import 'package:flutter/material.dart';

/// Premium Playful Finance color tokens
class AppColors {
  AppColors._();

  static ThemeMode _themeMode = ThemeMode.system;

  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
  }

  static Brightness get _effectiveBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  static bool get _isDark => _effectiveBrightness == Brightness.dark;

  static const Color lightPrimary = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F7);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightMuted = Color(0xFF6E6E73);
  static const Color lightBorder = Color(0xFFD2D2D7);

  static const Color darkPrimary = Color(0xFFE5E5EA);
  static const Color darkBackground = Color(0xFF0B0B0F);
  static const Color darkSurface = Color(0xFF17171C);
  static const Color darkText = Color(0xFFF5F5F7);
  static const Color darkMuted = Color(0xFFAEAEB2);
  static const Color darkBorder = Color(0xFF34353B);

  static Color get primary => _isDark ? darkPrimary : lightPrimary;
  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get text => _isDark ? darkText : lightText;
  static Color get muted => _isDark ? darkMuted : lightMuted;
  static Color get border => _isDark ? darkBorder : lightBorder;
  static Color get onPrimary => _isDark ? darkBackground : lightBackground;

  static const Color accentGreen = Color(0xFFA7E4C0);
  static const Color accentPink = Color(0xFFFFB3C6);
  static const Color accentPurple = Color(0xFFD4C4FB);
  static const Color accentYellow = Color(0xFFFDE293);

  static const Color success = accentGreen;
  static const Color warning = accentYellow;
  static const Color error = Color(0xFFE53935);
}

@immutable
class AppColorTokens {
  const AppColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.text,
    required this.muted,
    required this.border,
  });

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color text;
  final Color muted;
  final Color border;

  static const AppColorTokens light = AppColorTokens(
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightBackground,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: Color(0xFFEDEDF0),
    text: AppColors.lightText,
    muted: AppColors.lightMuted,
    border: AppColors.lightBorder,
  );

  static const AppColorTokens dark = AppColorTokens(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkBackground,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: Color(0xFF22232A),
    text: AppColors.darkText,
    muted: AppColors.darkMuted,
    border: AppColors.darkBorder,
  );
}
