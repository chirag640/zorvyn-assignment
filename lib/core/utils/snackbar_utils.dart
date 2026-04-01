import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Global snackbar utilities
class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))]), backgroundColor: AppColors.success, duration: duration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  static void showError(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))]), backgroundColor: AppColors.error, duration: duration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.info, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))]), backgroundColor: AppColors.info, duration: duration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  static void showWarning(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.warning, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))]), backgroundColor: AppColors.warning, duration: duration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}

