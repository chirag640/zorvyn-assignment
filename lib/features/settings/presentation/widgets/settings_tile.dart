import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? AppColors.text;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.rs(16),
        vertical: context.rs(4),
      ),
      leading: Container(
        width: context.rs(36),
        height: context.rs(36),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(context.rRadius(12)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: effectiveTitleColor,
          size: context.rIcon(20),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: effectiveTitleColor,
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  size: context.rIcon(22),
                  color: AppColors.muted,
                )
              : null),
      onTap: onTap,
    );
  }
}
