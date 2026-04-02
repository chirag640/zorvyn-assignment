import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import 'finance_ui_helpers.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final summary = ref.watch(financeSummaryProvider);
    final ringSize = (context.rValue(
      mobile: context.screenWidth - context.rs(92),
      tablet: 280,
      desktop: 320,
    )).clamp(context.rs(220), context.rs(320)).toDouble();

    return RefreshIndicator(
      onRefresh: () => ref.read(financeProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.rs(16),
          context.rs(18),
          context.rs(16),
          context.rs(120),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Goals and Challenges',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openGoalSetup(context, ref, state),
                  icon: Icon(Icons.tune_rounded, size: context.rIcon(16)),
                  label: Text(
                    'Adjust',
                    style: TextStyle(fontSize: context.rFont(12)),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(8)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(12)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(context.rRadius(16)),
              ),
              child: Wrap(
                spacing: context.rs(10),
                runSpacing: context.rs(8),
                children: [
                  _targetPill(
                    context,
                    'Weekly save ${formatCurrency(state.weeklySavingsTarget)}',
                  ),
                  _targetPill(
                    context,
                    'Weekly spend ${formatCurrency(state.weeklySpendLimit)}',
                  ),
                  _targetPill(
                    context,
                    'Monthly ${formatCurrency(state.monthlySavingsGoal)}',
                  ),
                  _targetPill(
                    context,
                    'Daily limit ${formatCurrency(state.dailySpendLimit)}',
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(context.rRadius(24)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: ringSize,
                    width: ringSize,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CustomPaint(
                          painter: _RingPainter(
                            savingsProgress:
                                summary.weeklySavingsProgress * value,
                            spendProgress: summary.weeklySpendProgress * value,
                            goalProgress: summary.monthlyGoalProgress * value,
                            ringTrackColor:
                                AppColors.muted.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${summary.currentStreak}',
                                  style: TextStyle(
                                    fontSize: context.rFont(40),
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  'day streak',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500,
                                    fontSize: context.rFont(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: context.rs(14)),
                  _legend(context),
                ],
              ),
            ),
            SizedBox(height: context.rs(16)),
            _challengeCard(
              context: context,
              title: 'Weekly Saver',
              subtitle:
                  'Target ${formatCurrency(state.weeklySavingsTarget)} net savings this week',
              progress: summary.weeklySavingsProgress,
              color: AppColors.accentGreen,
            ),
            SizedBox(height: context.rs(10)),
            _challengeCard(
              context: context,
              title: 'Discretionary Guard',
              subtitle:
                  'Stay within ${formatCurrency(state.weeklySpendLimit)} discretionary spend',
              progress: summary.weeklySpendProgress,
              color: AppColors.accentPink,
            ),
            SizedBox(height: context.rs(10)),
            _challengeCard(
              context: context,
              title: 'Monthly Goal',
              subtitle:
                  'Build toward ${formatCurrency(state.monthlySavingsGoal)} this month',
              progress: summary.monthlyGoalProgress,
              color: AppColors.accentPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetPill(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10),
        vertical: context.rs(6),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(context.rRadius(12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: context.rFont(12),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openGoalSetup(
    BuildContext context,
    WidgetRef ref,
    FinanceState state,
  ) async {
    final weeklySavingsController = TextEditingController(
        text: state.weeklySavingsTarget.toStringAsFixed(0));
    final weeklySpendController =
        TextEditingController(text: state.weeklySpendLimit.toStringAsFixed(0));
    final monthlyGoalController = TextEditingController(
        text: state.monthlySavingsGoal.toStringAsFixed(0));
    final dailyLimitController =
        TextEditingController(text: state.dailySpendLimit.toStringAsFixed(0));

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.rRadius(24)),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          context.rs(16),
          context.rs(12),
          context.rs(16),
          context.rs(24) + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Adjust targets',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: context.rs(12)),
            _targetInput(
                context, weeklySavingsController, 'Weekly savings target'),
            SizedBox(height: context.rs(10)),
            _targetInput(context, weeklySpendController, 'Weekly spend limit'),
            SizedBox(height: context.rs(10)),
            _targetInput(
                context, monthlyGoalController, 'Monthly savings goal'),
            SizedBox(height: context.rs(10)),
            _targetInput(
                context, dailyLimitController, 'Daily streak spend limit'),
            SizedBox(height: context.rs(14)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save targets'),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true || !context.mounted) {
      return;
    }

    final weeklySavings = double.tryParse(weeklySavingsController.text.trim());
    final weeklySpend = double.tryParse(weeklySpendController.text.trim());
    final monthlyGoal = double.tryParse(monthlyGoalController.text.trim());
    final dailyLimit = double.tryParse(dailyLimitController.text.trim());

    if ([weeklySavings, weeklySpend, monthlyGoal, dailyLimit].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values.')),
      );
      return;
    }

    await ref.read(financeProvider.notifier).updateGoalSettings(
          weeklySavingsTarget: weeklySavings!,
          weeklySpendLimit: weeklySpend!,
          monthlySavingsGoal: monthlyGoal!,
          dailySpendLimit: dailyLimit!,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal targets updated.')),
    );
  }

  Widget _targetInput(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: activeCurrencySymbol,
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }

  Widget _legend(BuildContext context) {
    return Wrap(
      spacing: context.rs(14),
      runSpacing: context.rs(8),
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: AppColors.accentGreen, label: 'Savings'),
        _LegendItem(color: AppColors.accentPink, label: 'Spend limit'),
        _LegendItem(color: AppColors.accentPurple, label: 'Monthly goal'),
      ],
    );
  }

  Widget _challengeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
  }) {
    final normalized = progress.clamp(0, 1).toDouble();
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
            title,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: context.rFont(16),
            ),
          ),
          SizedBox(height: context.rs(3)),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
              fontSize: context.rFont(13),
            ),
          ),
          SizedBox(height: context.rs(10)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.rRadius(100)),
            child: LinearProgressIndicator(
              minHeight: context.rs(6),
              value: normalized,
              color: color,
              backgroundColor: AppColors.muted.withValues(alpha: 0.16),
            ),
          ),
          SizedBox(height: context.rs(4)),
          Text(
            '${(normalized * 100).round()}% complete',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.rs(8),
          height: context.rs(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(context.rRadius(999)),
          ),
        ),
        SizedBox(width: context.rs(5)),
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
            fontSize: context.rFont(12),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.savingsProgress,
    required this.spendProgress,
    required this.goalProgress,
    required this.ringTrackColor,
  });

  final double savingsProgress;
  final double spendProgress;
  final double goalProgress;
  final Color ringTrackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = min(size.width, size.height) / 2;
    final strokeWidth = (base * 0.13).clamp(10.0, 16.0).toDouble();
    final gap = strokeWidth + (strokeWidth * 0.35);

    _drawRing(
      canvas: canvas,
      center: center,
      radius: base - (strokeWidth / 2),
      progress: savingsProgress,
      color: AppColors.accentGreen,
      strokeWidth: strokeWidth,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: base - (strokeWidth / 2) - gap,
      progress: spendProgress,
      color: AppColors.accentPink,
      strokeWidth: strokeWidth,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: base - (strokeWidth / 2) - (gap * 2),
      progress: goalProgress,
      color: AppColors.accentPurple,
      strokeWidth: strokeWidth,
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double progress,
    required Color color,
    required double strokeWidth,
  }) {
    if (radius <= 0) {
      return;
    }

    final bg = Paint()
      ..color = ringTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bg);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.savingsProgress != savingsProgress ||
        oldDelegate.spendProgress != spendProgress ||
        oldDelegate.goalProgress != goalProgress ||
        oldDelegate.ringTrackColor != ringTrackColor;
  }
}
