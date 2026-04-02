import 'package:flutter/material.dart';

import '../utils/app_responsive.dart';
import '../theme/app_colors.dart';

/// Global dialog utilities for success/failure messages
class DialogUtils {
  DialogUtils._();

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showStatusDialog(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      onPressed: onPressed,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return _showStatusDialog(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.error_outline,
      color: AppColors.error,
      onPressed: onPressed,
    );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.rRadius(16)),
        ),
        title: Text(title, style: TextStyle(fontSize: context.rFont(18))),
        content: Text(message, style: TextStyle(fontSize: context.rFont(14))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static void showLoading(BuildContext context,
      {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rRadius(16)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: context.rs(24),
                height: context.rs(24),
                child: CircularProgressIndicator(
                  strokeWidth: context.rThickness(3),
                ),
              ),
              SizedBox(height: context.rs(16)),
              Text(message, style: TextStyle(fontSize: context.rFont(14))),
            ],
          ),
        ),
      ),
    );
  }

  static void dismissLoading(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();

  static Future<void> _showStatusDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String buttonText,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.rRadius(16)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.rs(8)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: context.rIcon(28)),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: context.rFont(18),
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: context.rFont(14))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPressed?.call();
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
