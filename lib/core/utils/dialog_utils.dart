import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Global dialog utilities for success/failure messages
class DialogUtils {
  DialogUtils._();

  static Future<void> showSuccess(BuildContext context, {required String title, required String message, String buttonText = 'OK', VoidCallback? onPressed}) {
    return showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)))]), content: Text(message), actions: [TextButton(onPressed: () { Navigator.of(context).pop(); onPressed?.call(); }, child: Text(buttonText))]));
  }

  static Future<void> showError(BuildContext context, {required String title, required String message, String buttonText = 'OK', VoidCallback? onPressed}) {
    return showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.error_outline, color: AppColors.error, size: 32)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)))]), content: Text(message), actions: [TextButton(onPressed: () { Navigator.of(context).pop(); onPressed?.call(); }, child: Text(buttonText))]));
  }

  static Future<bool?> showConfirmation(BuildContext context, {required String title, required String message, String confirmText = 'Confirm', String cancelText = 'Cancel'}) {
    return showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)), ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmText))]));
  }

  static void showLoading(BuildContext context, {String message = 'Loading...'}) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => PopScope(canPop: false, child: AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), content: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)]))));
  }

  static void dismissLoading(BuildContext context) => Navigator.of(context, rootNavigator: true).pop();
}

