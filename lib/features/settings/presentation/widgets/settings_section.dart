import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.rRadius(22));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(16),
            context.rs(20),
            context.rs(16),
            context.rs(8),
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: context.rs(1.2),
                ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.rs(16)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.muted.withValues(alpha: 0.16),
              width: context.rThickness(1),
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
