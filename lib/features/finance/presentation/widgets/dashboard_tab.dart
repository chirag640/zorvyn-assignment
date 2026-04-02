import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import 'finance_ui_helpers.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({
    super.key,
    required this.onOpenAdd,
  });

  final VoidCallback onOpenAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final summary = ref.watch(financeSummaryProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(financeProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.rs(20),
                context.rs(18),
                context.rs(20),
                context.rs(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Available Balance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  SizedBox(height: context.rs(4)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      formatCurrency(summary.balance),
                      key: ValueKey<String>(
                        'balance-${summary.balance.toStringAsFixed(2)}',
                      ),
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: context.rs(16)),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(state.chartPulseToken),
                    tween: Tween(begin: 0.97, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _sparklineCard(context, summary),
                  ),
                  SizedBox(height: context.rs(14)),
                  _summaryRow(context, summary),
                  if (summary.currentStreak >= 7) ...[
                    SizedBox(height: context.rs(12)),
                    _feedbackPill(
                      context,
                      color: AppColors.accentYellow,
                      text:
                          'Great consistency: ${summary.currentStreak}-day streak active.',
                    ),
                  ],
                  if (summary.monthlyGoalProgress >= 1) ...[
                    SizedBox(height: context.rs(8)),
                    _feedbackPill(
                      context,
                      color: AppColors.accentGreen,
                      text:
                          'Monthly savings goal reached. Keep momentum going.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (state.transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(context.rs(24)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to your money.',
                        style: TextStyle(
                          fontSize: context.rFont(24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: context.rs(8)),
                      Text(
                        'Start by adding your first expense.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      SizedBox(height: context.rs(18)),
                      OutlinedButton(
                        onPressed: onOpenAdd,
                        child: const Text('Add transaction'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.rs(20),
                  context.rs(8),
                  context.rs(20),
                  context.rs(124),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: context.rs(12)),
                    SizedBox(
                      height: context.rs(114),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: min(8, state.transactions.length),
                        separatorBuilder: (_, __) =>
                            SizedBox(width: context.rs(10)),
                        itemBuilder: (context, index) {
                          final tx = state.transactions[index];
                          final ui = categoryUiByName(tx.category);
                          return Container(
                            width: context.rs(120),
                            padding: EdgeInsets.all(context.rs(12)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(context.rRadius(20)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: context.rs(26),
                                  height: context.rs(26),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: ui.color,
                                    borderRadius: BorderRadius.circular(
                                      context.rRadius(8),
                                    ),
                                  ),
                                  child: Text(
                                    ui.badge,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: context.rFont(10),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  tx.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: context.rFont(13),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: context.rs(2)),
                                Text(
                                  tx.type == FinanceTransactionType.expense
                                      ? '-${formatCurrency(tx.amount)}'
                                      : '+${formatCurrency(tx.amount)}',
                                  style: TextStyle(
                                    color: tx.type ==
                                            FinanceTransactionType.expense
                                        ? AppColors.text
                                        : AppColors.accentGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: context.rFont(14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedbackPill(BuildContext context,
      {required Color color, required String text}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12),
        vertical: context.rs(10),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.rRadius(14)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.rFont(12),
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, FinanceSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context: context,
            label: 'Income',
            value: formatCurrency(summary.totalIncome),
            color: AppColors.accentGreen,
          ),
        ),
        SizedBox(width: context.rs(10)),
        Expanded(
          child: _metricCard(
            context: context,
            label: 'Expenses',
            value: formatCurrency(summary.totalExpense),
            color: AppColors.accentPink,
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: context.rFont(13),
            ),
          ),
          SizedBox(height: context.rs(6)),
          Row(
            children: [
              Container(
                width: context.rs(8),
                height: context.rs(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(context.rRadius(99)),
                ),
              ),
              SizedBox(width: context.rs(6)),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: context.rFont(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sparklineCard(BuildContext context, FinanceSummary summary) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.rs(16),
        context.rs(16),
        context.rs(16),
        context.rs(14),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily spending',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(13),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.rs(8)),
          SizedBox(
            height: context.rs(76),
            child: CustomPaint(
              painter: _SparklinePainter(values: summary.sparkline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.height * 0.04).clamp(2.0, 4.5).toDouble()
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (values.isEmpty) {
      return;
    }

    final maxValue = values.reduce(max);
    final normalizedMax = max(maxValue, 1);
    final denominator = values.length > 1 ? values.length - 1 : 1;

    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / denominator;
      final y = size.height - (values[i] / normalizedMax) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
