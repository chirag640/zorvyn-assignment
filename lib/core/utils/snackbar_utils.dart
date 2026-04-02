import 'package:flutter/material.dart';

import '../utils/app_responsive.dart';
import '../theme/app_colors.dart';

/// Global snackbar utilities
class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      icon: Icons.check_circle,
      color: AppColors.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      icon: Icons.error,
      color: AppColors.error,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      icon: Icons.info,
      color: AppColors.accentPurple,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      icon: Icons.warning,
      color: AppColors.warning,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: context.rIcon(20)),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.rFont(14),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.rRadius(12)),
        ),
      ),
    );
  }
}
