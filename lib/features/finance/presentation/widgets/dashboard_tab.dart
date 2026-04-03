import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animation/motion_spec.dart';
import '../../../../core/feature_flags/feature_flags_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/finance_value_provider.dart';
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
    final featureFlags = ref.watch(featureFlagsProvider);
    final reduceMotion = ref
        .watch(settingsProvider.select((state) => state.reduceMotionEnabled));
    final animationDuration = MotionSpec.duration(
      MotionTier.standard,
      reduceMotion: reduceMotion || !featureFlags.enhancedAnimations,
    );
    final recurringPatterns = ref.watch(financeRecurringPatternsProvider);
    final budgetWarnings = ref.watch(financeBudgetWarningsProvider);
    final dueBills = ref.watch(financeDueBillsProvider);
    final forecast = ref.watch(financeCashflowForecastProvider);
    final netWorth = ref.watch(financeNetWorthSnapshotProvider);

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
                    duration: animationDuration,
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
                    duration: animationDuration,
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _sparklineCard(context, summary),
                  ),
                  SizedBox(height: context.rs(14)),
                  _summaryRow(context, summary),
                  SizedBox(height: context.rs(10)),
                  _compactInsightStrip(
                    context,
                    forecast: forecast,
                    budgetWarningsCount: budgetWarnings.length,
                    dueBillsCount: dueBills.length,
                    recurringCount: recurringPatterns.length,
                    netWorthValue: netWorth.netWorth,
                    showForecast: featureFlags.forecastCards,
                    showBills: featureFlags.billsTrackerEnabled,
                    showRecurring: featureFlags.recurringDetectionEnabled,
                    showNetWorth: featureFlags.netWorthEnabled,
                  ),
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

  Widget _compactInsightStrip(
    BuildContext context, {
    required CashflowForecast forecast,
    required int budgetWarningsCount,
    required int dueBillsCount,
    required int recurringCount,
    required double netWorthValue,
    required bool showForecast,
    required bool showBills,
    required bool showRecurring,
    required bool showNetWorth,
  }) {
    final chips = <Widget>[];

    if (showForecast) {
      final isPositive = forecast.projectedBalance7Days >= 0;
      chips.add(
        _compactInsightChip(
          context,
          label: '7d ${formatCurrency(forecast.projectedBalance7Days)}',
          color: isPositive ? AppColors.accentGreen : AppColors.accentPink,
        ),
      );
    }

    if (budgetWarningsCount > 0) {
      chips.add(
        _compactInsightChip(
          context,
          label:
              '$budgetWarningsCount budget alert${budgetWarningsCount == 1 ? '' : 's'}',
          color: AppColors.accentYellow,
        ),
      );
    }

    if (showBills && dueBillsCount > 0) {
      chips.add(
        _compactInsightChip(
          context,
          label: '$dueBillsCount bill${dueBillsCount == 1 ? '' : 's'} due',
          color: AppColors.accentPink,
        ),
      );
    }

    if (showRecurring && recurringCount > 0) {
      chips.add(
        _compactInsightChip(
          context,
          label:
              '$recurringCount recurring signal${recurringCount == 1 ? '' : 's'}',
          color: AppColors.accentPurple,
        ),
      );
    }

    if (showNetWorth) {
      chips.add(
        _compactInsightChip(
          context,
          label: 'Net ${formatCurrency(netWorthValue)}',
          color:
              netWorthValue >= 0 ? AppColors.accentGreen : AppColors.accentPink,
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < chips.length; index++) ...[
              if (index > 0) SizedBox(width: context.rs(8)),
              chips[index],
            ],
          ],
        ),
      ),
    );
  }

  Widget _compactInsightChip(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(10),
        vertical: context.rs(6),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.rRadius(999)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: context.rFont(11),
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

  Widget _forecastCard(BuildContext context, CashflowForecast forecast) {
    final is7Positive = forecast.projectedBalance7Days >= 0;
    final is30Positive = forecast.projectedBalance30Days >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cashflow forecast',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: context.rFont(14),
            ),
          ),
          SizedBox(height: context.rs(8)),
          Row(
            children: [
              Expanded(
                child: _forecastCell(
                  context,
                  label: '7 days',
                  value: formatCurrency(forecast.projectedBalance7Days),
                  isPositive: is7Positive,
                ),
              ),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: _forecastCell(
                  context,
                  label: '30 days',
                  value: formatCurrency(forecast.projectedBalance30Days),
                  isPositive: is30Positive,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(10)),
          _forecastBreakdownRow(
            context,
            label: '7d contributions',
            trend: forecast.trendContribution7Days,
            recurring: forecast.recurringContribution7Days,
            bills: forecast.billsContribution7Days,
          ),
          SizedBox(height: context.rs(8)),
          _forecastBreakdownRow(
            context,
            label: '30d contributions',
            trend: forecast.trendContribution30Days,
            recurring: forecast.recurringContribution30Days,
            bills: forecast.billsContribution30Days,
          ),
        ],
      ),
    );
  }

  Widget _forecastBreakdownRow(
    BuildContext context, {
    required String label,
    required double trend,
    required double recurring,
    required double bills,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(10)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(context.rRadius(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.rs(6)),
          Wrap(
            spacing: context.rs(8),
            runSpacing: context.rs(6),
            children: [
              _forecastContributionPill(context, title: 'Trend', value: trend),
              _forecastContributionPill(context,
                  title: 'Recurring', value: recurring),
              _forecastContributionPill(context, title: 'Bills', value: bills),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastContributionPill(
    BuildContext context, {
    required String title,
    required double value,
  }) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.accentGreen : AppColors.accentPink;
    final sign = isPositive ? '+' : '-';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(8),
        vertical: context.rs(6),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(context.rRadius(12)),
      ),
      child: Text(
        '$title $sign${formatCurrency(value.abs())}',
        style: TextStyle(
          color: color,
          fontSize: context.rFont(11),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _forecastCell(
    BuildContext context, {
    required String label,
    required String value,
    required bool isPositive,
  }) {
    return Container(
      padding: EdgeInsets.all(context.rs(10)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(context.rRadius(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(12),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.rs(4)),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? AppColors.accentGreen : AppColors.accentPink,
              fontSize: context.rFont(14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetWarningsCard(
    BuildContext context,
    List<BudgetWarning> warnings,
  ) {
    final visible = warnings.take(3).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget alerts',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: context.rFont(14),
            ),
          ),
          SizedBox(height: context.rs(8)),
          for (final warning in visible)
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      warning.category,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: context.rFont(13),
                      ),
                    ),
                  ),
                  Text(
                    '${(warning.percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: warning.percent >= 1
                          ? AppColors.accentPink
                          : AppColors.accentYellow,
                      fontWeight: FontWeight.w700,
                      fontSize: context.rFont(13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dueBillsCard(BuildContext context, List<FinanceBillEntry> bills) {
    final visible = bills.take(3).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bills due soon',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: context.rFont(14),
            ),
          ),
          SizedBox(height: context.rs(8)),
          for (final bill in visible)
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${bill.name} · ${shortDate(bill.nextDueAt)}',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: context.rFont(13),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: context.rs(8)),
                  Text(
                    formatCurrency(bill.amount),
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: context.rFont(13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _netWorthCard(BuildContext context, NetWorthSnapshot snapshot) {
    final trendPositive = snapshot.trendPercent >= 0;
    final trendLabel = snapshot.trendPercent.isFinite
        ? '${snapshot.trendPercent >= 0 ? '+' : ''}${snapshot.trendPercent.toStringAsFixed(1)}%'
        : '0.0%';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net worth',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                    fontSize: context.rFont(12),
                  ),
                ),
                SizedBox(height: context.rs(4)),
                Text(
                  formatCurrency(snapshot.netWorth),
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: context.rFont(16),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(10),
              vertical: context.rs(6),
            ),
            decoration: BoxDecoration(
              color: trendPositive
                  ? AppColors.accentGreen.withValues(alpha: 0.15)
                  : AppColors.accentPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(context.rRadius(12)),
            ),
            child: Text(
              trendLabel,
              style: TextStyle(
                color: trendPositive
                    ? AppColors.accentGreen
                    : AppColors.accentPink,
                fontWeight: FontWeight.w700,
                fontSize: context.rFont(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recurringPatternsCard(
    BuildContext context,
    List<RecurringTransactionPattern> patterns,
  ) {
    final visible = patterns.take(2).toList(growable: false);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurring signals',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: context.rFont(14),
            ),
          ),
          SizedBox(height: context.rs(8)),
          for (final pattern in visible)
            Padding(
              padding: EdgeInsets.only(bottom: context.rs(8)),
              child: Text(
                '${pattern.category} · every ${pattern.averageIntervalDays}d · ${formatCurrency(pattern.amount)}',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: context.rFont(12),
                ),
              ),
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
