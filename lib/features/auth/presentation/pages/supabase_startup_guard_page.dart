import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';

class SupabaseStartupGuardPage extends StatelessWidget {
  const SupabaseStartupGuardPage({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.rs(20);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = (constraints.maxHeight - (horizontalPadding * 2))
                .clamp(0.0, double.infinity)
                .toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.rValue(
                        mobile: double.infinity,
                        tablet: 520,
                        desktop: 560,
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(context.rs(20)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(context.rRadius(24)),
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.18),
                          width: context.rThickness(1),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: context.rIcon(42),
                            color: AppColors.text,
                          ),
                          SizedBox(height: context.rs(12)),
                          Text(
                            'Supabase setup required',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: context.rs(10)),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.muted,
                                ),
                          ),
                          SizedBox(height: context.rs(16)),
                          const _ChecklistItem(
                            text:
                                'Set SUPABASE_URL and SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY) in frontend/.env.',
                          ),
                          const _ChecklistItem(
                            text:
                                'Keep .env listed under flutter assets in pubspec.yaml.',
                          ),
                          const _ChecklistItem(
                            text:
                                'After env or pubspec changes, do a full app restart (not just hot reload).',
                          ),
                          SizedBox(height: context.rs(18)),
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry Supabase Initialization'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.rs(2)),
            child: Container(
              width: context.rs(7),
              height: context.rs(7),
              decoration: BoxDecoration(
                color: AppColors.text,
                borderRadius: BorderRadius.circular(context.rRadius(99)),
              ),
            ),
          ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
