import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return _buildTheme(
      tokens: AppColorTokens.light,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      tokens: AppColorTokens.dark,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _buildTheme({
    required AppColorTokens tokens,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: AppColors.accentPurple,
      onSecondary: tokens.text,
      tertiary: AppColors.accentGreen,
      onTertiary: tokens.text,
      error: AppColors.error,
      onError: tokens.onPrimary,
      surface: tokens.surface,
      onSurface: tokens.text,
      onSurfaceVariant: tokens.muted,
      outline: tokens.border,
      surfaceTint: Colors.transparent,
    );

    final textTheme = buildTextTheme(
      primaryTextColor: tokens.text,
      secondaryTextColor: tokens.muted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: tokens.background,
        foregroundColor: tokens.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: tokens.surface,
      dividerColor: tokens.border.withValues(alpha: 0.4),
      shadowColor: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.34 : 0.08,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: tokens.muted),
        hintStyle: TextStyle(color: tokens.muted),
        prefixIconColor: tokens.muted,
        suffixIconColor: tokens.muted,
        border: _inputBorder(tokens.border.withValues(alpha: 0.7)),
        enabledBorder: _inputBorder(tokens.border.withValues(alpha: 0.7)),
        focusedBorder: _inputBorder(tokens.primary),
        errorBorder: _inputBorder(AppColors.error.withValues(alpha: 0.8)),
        focusedErrorBorder: _inputBorder(AppColors.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: tokens.border.withValues(alpha: 0.8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface,
        selectedColor: tokens.primary,
        secondarySelectedColor: tokens.primary,
        disabledColor: tokens.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.bodySmall?.copyWith(color: tokens.text),
        secondaryLabelStyle:
            textTheme.bodySmall?.copyWith(color: tokens.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: tokens.border.withValues(alpha: 0.7),
          ),
        ),
        brightness: brightness,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color),
    );
  }
}
