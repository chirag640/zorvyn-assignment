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
  int selectedMonthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final monthlySnapshot = _MonthlyInsightsSnapshot.fromTransactions(
      transactions: state.transactions,
      monthOffset: selectedMonthOffset,
      now: DateTime.now(),
    );
    final weekly = monthlySnapshot.weeklyExpenses;
    final safeBarIndex =
        weekly.isEmpty ? 0 : selectedBar.clamp(0, weekly.length - 1).toInt();
    final selectedValue =
        weekly.isEmpty ? 0.0 : weekly[safeBarIndex].toDouble();

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
            _MonthPicker(
              selectedIndex: selectedMonthOffset,
              onSelected: (index) {
                if (index == selectedMonthOffset) {
                  return;
                }

                setState(() {
                  selectedMonthOffset = index;
                  selectedBar = 0;
                });
              },
            ),
            SizedBox(height: context.rs(14)),
            _insightCards(context, monthlySnapshot),
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
                    'Selected period (${monthlySnapshot.label}): ${formatCurrency(selectedValue)}',
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
                      selectedIndex: safeBarIndex,
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
            ..._buildCategoryRows(context, monthlySnapshot.categorySpending),
          ],
        ),
      ),
    );
  }

  Widget _insightCards(
    BuildContext context,
    _MonthlyInsightsSnapshot snapshot,
  ) {
    final weekDirection = snapshot.weeklyDeltaPercent <= 0 ? 'down' : 'up';
    final monthDirection = snapshot.monthlyDeltaPercent <= 0 ? 'down' : 'up';
    final absWeekly = snapshot.weeklyDeltaPercent.abs();
    final absMonthly = snapshot.monthlyDeltaPercent.abs();

    return Column(
      children: [
        _insightCard(
          context,
          title: 'Top spending category',
          value: snapshot.topCategoryAmount <= 0
              ? 'No spend in ${snapshot.label.toLowerCase()}'
              : '${snapshot.topCategoryName} • ${formatCurrency(snapshot.topCategoryAmount)}',
          helper: 'Highest spend area in ${snapshot.label.toLowerCase()}.',
          accent: AppColors.accentPink,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Week over week',
          value:
              '${absWeekly.toStringAsFixed(0)}% $weekDirection vs previous week',
          helper:
              'Current week: ${formatCurrency(snapshot.currentWeekExpense)} | Previous: ${formatCurrency(snapshot.previousWeekExpense)}',
          accent: AppColors.accentGreen,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Monthly trend',
          value:
              '${absMonthly.toStringAsFixed(0)}% $monthDirection vs previous month',
          helper:
              '${snapshot.label} expenses ${formatCurrency(snapshot.currentMonthExpense)}.',
          accent: AppColors.accentPurple,
        ),
        SizedBox(height: context.rs(8)),
        _insightCard(
          context,
          title: 'Frequent transaction type',
          value:
              '${snapshot.mostFrequentType == FinanceTransactionType.expense ? 'Expense' : 'Income'} • ${snapshot.mostFrequentTypeCount} records',
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

class _MonthlyInsightsSnapshot {
  const _MonthlyInsightsSnapshot({
    required this.label,
    required this.weeklyExpenses,
    required this.categorySpending,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.currentWeekExpense,
    required this.previousWeekExpense,
    required this.weeklyDeltaPercent,
    required this.currentMonthExpense,
    required this.previousMonthExpense,
    required this.monthlyDeltaPercent,
    required this.mostFrequentType,
    required this.mostFrequentTypeCount,
  });

  final String label;
  final List<double> weeklyExpenses;
  final Map<String, double> categorySpending;
  final String topCategoryName;
  final double topCategoryAmount;
  final double currentWeekExpense;
  final double previousWeekExpense;
  final double weeklyDeltaPercent;
  final double currentMonthExpense;
  final double previousMonthExpense;
  final double monthlyDeltaPercent;
  final FinanceTransactionType mostFrequentType;
  final int mostFrequentTypeCount;

  static const List<String> labels = <String>[
    'This month',
    'Last month',
    '2 mo ago',
  ];

  factory _MonthlyInsightsSnapshot.fromTransactions({
    required List<FinanceTransaction> transactions,
    required int monthOffset,
    required DateTime now,
  }) {
    final safeOffset = monthOffset.clamp(0, labels.length - 1).toInt();
    final monthStart = _monthStart(now, safeOffset);
    final monthEnd =
        DateTime(monthStart.year, monthStart.month + 1, 1).subtract(
      const Duration(milliseconds: 1),
    );
    final previousMonthStart = DateTime(monthStart.year, monthStart.month - 1);
    final previousMonthEnd = monthStart.subtract(
      const Duration(milliseconds: 1),
    );

    final weeklyExpenses = List<double>.filled(4, 0);
    final categorySpending = <String, double>{};
    var currentMonthExpense = 0.0;
    var previousMonthExpense = 0.0;
    var incomeCount = 0;
    var expenseCount = 0;

    for (final tx in transactions) {
      final inCurrentMonth = _inRange(tx.date, monthStart, monthEnd);
      if (inCurrentMonth) {
        if (tx.type == FinanceTransactionType.income) {
          incomeCount++;
        } else {
          expenseCount++;
          currentMonthExpense += tx.amount;
          categorySpending[tx.category] =
              (categorySpending[tx.category] ?? 0) + tx.amount;

          final bucket = ((tx.date.day - 1) ~/ 7).clamp(0, 3).toInt();
          weeklyExpenses[bucket] += tx.amount;
        }
      }

      if (tx.type == FinanceTransactionType.expense &&
          _inRange(tx.date, previousMonthStart, previousMonthEnd)) {
        previousMonthExpense += tx.amount;
      }
    }

    String topCategoryName = 'N/A';
    double topCategoryAmount = 0;
    if (categorySpending.isNotEmpty) {
      final top = categorySpending.entries.reduce(
        (left, right) => left.value >= right.value ? left : right,
      );
      topCategoryName = top.key;
      topCategoryAmount = top.value;
    }

    final weekBucket =
        safeOffset == 0 ? ((now.day - 1) ~/ 7).clamp(0, 3).toInt() : 3;
    final currentWeekExpense = weeklyExpenses[weekBucket];
    final previousWeekExpense =
        weekBucket > 0 ? weeklyExpenses[weekBucket - 1] : 0.0;

    final mostFrequentType = incomeCount > expenseCount
        ? FinanceTransactionType.income
        : FinanceTransactionType.expense;
    final mostFrequentTypeCount =
        incomeCount > expenseCount ? incomeCount : expenseCount;

    return _MonthlyInsightsSnapshot(
      label: labels[safeOffset],
      weeklyExpenses: weeklyExpenses,
      categorySpending: categorySpending,
      topCategoryName: topCategoryName,
      topCategoryAmount: topCategoryAmount,
      currentWeekExpense: currentWeekExpense,
      previousWeekExpense: previousWeekExpense,
      weeklyDeltaPercent:
          _deltaPercent(currentWeekExpense, previousWeekExpense),
      currentMonthExpense: currentMonthExpense,
      previousMonthExpense: previousMonthExpense,
      monthlyDeltaPercent:
          _deltaPercent(currentMonthExpense, previousMonthExpense),
      mostFrequentType: mostFrequentType,
      mostFrequentTypeCount: mostFrequentTypeCount,
    );
  }

  static DateTime _monthStart(DateTime now, int monthOffset) {
    final monthIndex = (now.year * 12) + now.month - 1 - monthOffset;
    final year = monthIndex ~/ 12;
    final month = (monthIndex % 12) + 1;
    return DateTime(year, month, 1);
  }

  static bool _inRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  static double _deltaPercent(double current, double previous) {
    if (previous <= 0) {
      return current <= 0 ? 0 : 100;
    }

    return ((current - previous) / previous) * 100;
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
  const _MonthPicker({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = _MonthlyInsightsSnapshot.labels;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(
              right: index < items.length - 1 ? context.rs(8) : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(context.rRadius(14)),
              child: Ink(
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
              ),
            ),
          );
        }),
      ),
    );
  }
}
