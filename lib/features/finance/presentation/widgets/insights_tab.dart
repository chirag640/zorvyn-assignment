import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import 'finance_ui_helpers.dart';

class InsightsTab extends ConsumerStatefulWidget {
  const InsightsTab({super.key});

  @override
  ConsumerState<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<InsightsTab> {
  int selectedBar = 0;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(financeSummaryProvider);
    final weekly = summary.weeklyExpenses;
    final selectedValue = weekly.isEmpty
        ? 0.0
        : weekly[selectedBar.clamp(0, weekly.length - 1)].toDouble();

    return RefreshIndicator(
      onRefresh: () => ref.read(financeProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.rs(16),
          context.rs(16),
          context.rs(16),
          context.rs(120),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: context.rs(12)),
            const _MonthPicker(),
            SizedBox(height: context.rs(14)),
            _insightCards(context, summary),
            SizedBox(height: context.rs(14)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.rs(16)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(context.rRadius(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected period: ${formatCurrency(selectedValue)}',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: context.rFont(16),
                    ),
                  ),
                  SizedBox(height: context.rs(14)),
                  SizedBox(
                    height: context.rs(180),
                    child: _BarChart(
                      values: weekly,
                      selectedIndex: selectedBar,
                      onSelect: (index) {
                        setState(() {
                          selectedBar = index;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.rs(16)),
            Text(
              'Category breakdown',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: context.rFont(18),
              ),
            ),
            SizedBox(height: context.rs(8)),
            ..._buildCategoryRows(context, summary.categorySpending),
          ],
        ),
      ),
    );
  }

  Widget _insightCards(BuildContext context, FinanceSummary summary) {
    final weekDirection = summary.weeklyDeltaPercent <= 0 ? 'down' : 'up';
    final monthDirection = summary.monthlyDeltaPercent <= 0 ? 'down' : 'up';
    final absWeekly = summary.weeklyDeltaPercent.abs();
    final absMonthly = summary.monthlyDeltaPercent.abs();

    return Column(
      children: [
        _insightCard(
          context,
          title: 'Top spending category',
          value: summary.topCategoryAmount <= 0
              ? 'No spend this month'
              : '${summary.topCategoryName} • ${formatCurrency(summary.topCategoryAmount)}',
          helper:
              'Your highest spend area this month. Track this to control budget drift.',
          accent: AppColors.accentPink,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Week over week',
          value:
              '${absWeekly.toStringAsFixed(0)}% $weekDirection vs previous week',
          helper:
              'Current week: ${formatCurrency(summary.currentWeekExpense)} | Previous: ${formatCurrency(summary.previousWeekExpense)}',
          accent: AppColors.accentGreen,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Monthly trend',
          value:
              '${absMonthly.toStringAsFixed(0)}% $monthDirection vs previous month',
          helper:
              'Current month expenses ${formatCurrency(summary.currentMonthExpense)}.',
          accent: AppColors.accentPurple,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Frequent transaction type',
          value:
              '${summary.mostFrequentType == FinanceTransactionType.expense ? 'Expense' : 'Income'} • ${summary.mostFrequentTypeCount} records',
          helper:
              'Use this signal to rebalance behavior and reduce repetitive leak categories.',
          accent: AppColors.accentYellow,
        ),
      ],
    );
  }

  Widget _insightCard(
    BuildContext context, {
    required String title,
    required String value,
    required String helper,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.rs(12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.rRadius(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.rs(8),
                height: context.rs(8),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(context.rRadius(99)),
                ),
              ),
              SizedBox(width: context.rs(6)),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: context.rFont(14),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(6)),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontSize: context.rFont(13),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.rs(4)),
          Text(
            helper,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(12),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows(
      BuildContext context, Map<String, double> map) {
    if (map.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(top: context.rs(12)),
          child: Text(
            'No monthly insights yet. Add transactions to reveal patterns.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: context.rFont(13),
            ),
          ),
        ),
      ];
    }

    final total = map.values.fold<double>(0, (sum, amount) => sum + amount);
    final rows = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return rows.map((entry) {
      final ui = categoryUiByName(entry.key);
      final pct = total <= 0 ? 0 : (entry.value / total) * 100;

      return Container(
        margin: EdgeInsets.only(top: context.rs(8)),
        padding: EdgeInsets.all(context.rs(12)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(context.rRadius(18)),
        ),
        child: Row(
          children: [
            Container(
              width: context.rs(40),
              height: context.rs(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ui.color,
                borderRadius: BorderRadius.circular(context.rRadius(12)),
              ),
              child: Text(
                ui.badge,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.rFont(12),
                ),
              ),
            ),
            SizedBox(width: context.rs(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: context.rFont(15),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}% of total',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: context.rFont(13),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(entry.value),
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: context.rFont(14),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<double> values;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Center(
        child: Text(
          'No weekly data yet',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: context.rFont(13),
          ),
        ),
      );
    }

    final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
    final normalizedMax = maxValue <= 0 ? 1 : maxValue;
    final colors = <Color>[
      AppColors.accentGreen,
      AppColors.accentPink,
      AppColors.accentPurple,
      AppColors.accentYellow,
    ];
    final maxBarHeight = context.rs(132);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(values.length, (index) {
        final value = values[index];
        final isSelected = selectedIndex == index;
        final height = ((value / normalizedMax) * maxBarHeight)
            .clamp(context.rs(10), maxBarHeight)
            .toDouble();
        return GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isSelected ? 1 : 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: context.rs(12),
                  height: height,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(context.rRadius(8)),
                  ),
                ),
                SizedBox(height: context.rs(8)),
                Text(
                  'W${index + 1}',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: context.rFont(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker();

  @override
  Widget build(BuildContext context) {
    const items = ['This month', 'Last month', '2 mo ago'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == 0;
          return Container(
            margin: EdgeInsets.only(
                right: index < items.length - 1 ? context.rs(8) : 0),
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(12),
              vertical: context.rs(8),
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(context.rRadius(14)),
            ),
            child: Text(
              items[index],
              style: TextStyle(
                color: selected ? AppColors.background : AppColors.text,
                fontSize: context.rFont(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }
}
