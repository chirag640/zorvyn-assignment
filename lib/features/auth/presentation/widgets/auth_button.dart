import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';

/// Custom button for authentication forms
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = AppColors.onPrimary;

    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: context.rFont(16),
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        );

    return SizedBox(
      height: context.rs(54),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.8),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rRadius(18)),
          ),
          elevation: 0,
          textStyle: textStyle,
        ),
        child: isLoading
            ? SizedBox(
                height: context.rs(24),
                width: context.rs(24),
                child: CircularProgressIndicator(
                  strokeWidth: context.rThickness(2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor,
                  ),
                ),
              )
            : Text(
                label,
                style: textStyle,
              ),
      ),
    );
  }
}
