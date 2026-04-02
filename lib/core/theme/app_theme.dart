import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.background,
        secondary: AppColors.accentPurple,
        onSecondary: AppColors.text,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: buildTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      cardColor: AppColors.surface,
      dividerColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: buildTextTheme().labelLarge,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return light();
  }
}
