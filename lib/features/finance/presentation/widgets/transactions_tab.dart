import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/haptic_feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../data/utils/finance_id_generator.dart';
import '../providers/finance_provider.dart';
import '../providers/finance_value_provider.dart';
import 'finance_ui_helpers.dart';

class TransactionsTab extends ConsumerStatefulWidget {
  const TransactionsTab({
    super.key,
    required this.onEditTransaction,
  });

  final ValueChanged<FinanceTransaction> onEditTransaction;

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  bool _isSyncingController = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(financeProvider).searchQuery,
    )..addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_isSyncingController) {
      return;
    }

    _searchDebounce?.cancel();
    final query = _searchController.text;
    _searchDebounce = Timer(
      const Duration(milliseconds: 180),
      () {
        if (!mounted) {
          return;
        }

        ref.read(financeProvider.notifier).setSearchQuery(query);
      },
    );
  }

  void _syncSearchController(String query) {
    if (_searchController.text == query) {
      return;
    }

    _isSyncingController = true;
    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _isSyncingController = false;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    _syncSearchController(state.searchQuery);
    final transactions = ref.watch(filteredTransactionsProvider);
    final hasActiveFilters = ref.watch(hasActiveFinanceFiltersProvider);
    final budgetWarnings = ref.watch(financeBudgetWarningsProvider);
    final dueBills = ref.watch(financeDueBillsProvider);
    final netWorthSnapshot = ref.watch(financeNetWorthSnapshotProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(16),
            context.rs(10),
            context.rs(16),
            context.rs(6),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions',
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.muted,
                size: context.rIcon(20),
              ),
              suffixIcon: state.searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        ref.read(financeProvider.notifier).setSearchQuery('');
                      },
                      icon: Icon(Icons.close, size: context.rIcon(18)),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.rRadius(14)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: context.rs(12),
              ),
            ),
          ),
        ),
        _buildFilters(context, ref, state, hasActiveFilters),
        if (budgetWarnings.isNotEmpty ||
            dueBills.isNotEmpty ||
            netWorthSnapshot.netWorth != 0)
          _buildManagementStrip(
            context,
            budgetWarningsCount: budgetWarnings.length,
            dueBillsCount: dueBills.length,
            netWorthValue: netWorthSnapshot.netWorth,
            onBudgets: _openBudgetManager,
            onBills: _openBillsManager,
            onNetWorth: _openNetWorthManager,
          ),
        Expanded(
          child: state.isLoading && state.transactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : transactions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () =>
                          ref.read(financeProvider.notifier).refresh(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: context.rs(84)),
                          Icon(
                            Icons.receipt_long_rounded,
                            size: context.rIcon(44),
                            color: AppColors.muted,
                          ),
                          SizedBox(height: context.rs(12)),
                          Center(
                            child: Text(
                              hasActiveFilters
                                  ? 'No transactions match your filters'
                                  : 'No transactions yet',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: context.rFont(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(financeProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          context.rs(16),
                          context.rs(6),
                          context.rs(16),
                          context.rs(110),
                        ),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.rs(6)),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final ui = categoryUiByName(tx.category);
                          return Dismissible(
                            key: ValueKey(tx.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDelete(context),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius:
                                    BorderRadius.circular(context.rRadius(14)),
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: context.rs(18)),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: context.rIcon(22),
                              ),
                            ),
                            onDismissed: (_) async {
                              final deleted = await ref
                                  .read(financeProvider.notifier)
                                  .deleteTransaction(tx.id);

                              if (deleted == null || !context.mounted) {
                                return;
                              }

                              final messenger = ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Transaction deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      ref
                                          .read(financeProvider.notifier)
                                          .restoreTransaction(deleted);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(context.rRadius(14)),
                              onTap: () => widget.onEditTransaction(tx),
                              child: Container(
                                padding: EdgeInsets.all(context.rs(10)),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    context.rRadius(14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: context.rs(34),
                                      height: context.rs(34),
                                      decoration: BoxDecoration(
                                        color: ui.color,
                                        borderRadius: BorderRadius.circular(
                                          context.rRadius(10),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        ui.badge,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: context.rFont(11),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.rs(10)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.category,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                              fontSize: context.rFont(14),
                                            ),
                                          ),
                                          SizedBox(height: context.rs(2)),
                                          Text(
                                            tx.note ?? shortDate(tx.date),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: context.rFont(12),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: context.rs(8)),
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
                                        fontSize: context.rFont(13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    FinanceState state,
    bool hasActiveFilters,
  ) {
    final notifier = ref.read(financeProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16),
        0,
        context.rs(16),
        context.rs(8),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChoiceChip(
                  context,
                  label: 'All',
                  selected: state.filterType == null,
                  onSelected: () => notifier.setFilterType(null),
                ),
                SizedBox(width: context.rs(8)),
                _buildChoiceChip(
                  context,
                  label: 'Income',
                  selected: state.filterType == FinanceTransactionType.income,
                  onSelected: () =>
                      notifier.setFilterType(FinanceTransactionType.income),
                ),
                SizedBox(width: context.rs(8)),
                _buildChoiceChip(
                  context,
                  label: 'Expense',
                  selected: state.filterType == FinanceTransactionType.expense,
                  onSelected: () =>
                      notifier.setFilterType(FinanceTransactionType.expense),
                ),
                SizedBox(width: context.rs(8)),
                PopupMenuButton<String?>(
                  tooltip: 'Category filter',
                  color: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 1,
                  offset: Offset(0, context.rs(4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.rRadius(14)),
                  ),
                  onSelected: notifier.setFilterCategory,
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...financeCategories.map(
                        (category) => PopupMenuItem<String?>(
                          value: category.name,
                          child: Text('${category.badge} ${category.name}'),
                        ),
                      ),
                    ];
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rs(12),
                      vertical: context.rs(8),
                    ),
                    decoration: BoxDecoration(
                      color: state.filterCategory == null
                          ? AppColors.surface
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(context.rRadius(14)),
                      border: Border.all(
                        color: state.filterCategory == null
                            ? Colors.transparent
                            : AppColors.primary.withValues(alpha: 0.35),
                        width: context.rThickness(1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined, size: context.rIcon(16)),
                        SizedBox(width: context.rs(6)),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: context.rs(112)),
                          child: Text(
                            state.filterCategory ?? 'All categories',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: context.rFont(12)),
                          ),
                        ),
                        SizedBox(width: context.rs(2)),
                        Icon(Icons.expand_more, size: context.rIcon(16)),
                      ],
                    ),
                  ),
                ),
                if (hasActiveFilters) ...[
                  SizedBox(width: context.rs(8)),
                  TextButton(
                    onPressed: notifier.clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: context.rs(8)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(
                  context,
                  state,
                  label: 'All time',
                  range: FinanceDateRange.all,
                  onTap: notifier.setDateRange,
                ),
                SizedBox(width: context.rs(8)),
                _buildDateChip(
                  context,
                  state,
                  label: 'This week',
                  range: FinanceDateRange.thisWeek,
                  onTap: notifier.setDateRange,
                ),
                SizedBox(width: context.rs(8)),
                _buildDateChip(
                  context,
                  state,
                  label: 'This month',
                  range: FinanceDateRange.thisMonth,
                  onTap: notifier.setDateRange,
                ),
                SizedBox(width: context.rs(8)),
                _buildDateChip(
                  context,
                  state,
                  label: 'Last 30 days',
                  range: FinanceDateRange.last30Days,
                  onTap: notifier.setDateRange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementStrip(
    BuildContext context, {
    required int budgetWarningsCount,
    required int dueBillsCount,
    required double netWorthValue,
    required VoidCallback onBudgets,
    required VoidCallback onBills,
    required VoidCallback onNetWorth,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16),
        0,
        context.rs(16),
        context.rs(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildManagerChip(
              context,
              icon: Icons.pie_chart_outline,
              label: budgetWarningsCount > 0
                  ? 'Budgets ($budgetWarningsCount)'
                  : 'Budgets',
              onTap: onBudgets,
            ),
            SizedBox(width: context.rs(6)),
            _buildManagerChip(
              context,
              icon: Icons.calendar_today_outlined,
              label: dueBillsCount > 0 ? 'Bills ($dueBillsCount)' : 'Bills',
              onTap: onBills,
            ),
            SizedBox(width: context.rs(6)),
            _buildManagerChip(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Net worth ${formatCurrency(netWorthValue)}',
              onTap: onNetWorth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: context.rIcon(14), color: AppColors.primary),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
          fontSize: context.rFont(11),
        ),
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onTap,
    );
  }

  Future<void> _openBudgetManager() async {
    final amountController = TextEditingController();
    var selectedCategory = financeCategories.first.name;
    var warningThreshold = 0.8;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final budgets = ref.read(financeValueProvider).budgets;
            final categories = <String>{
              ...financeCategories.map((item) => item.name),
              ...budgets.map((item) => item.category),
            }.toList(growable: false)
              ..sort();

            if (!categories.contains(selectedCategory) &&
                categories.isNotEmpty) {
              selectedCategory = categories.first;
            }

            return AlertDialog(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: const Text('Category Budgets'),
              content: SizedBox(
                width: context.rValue(mobile: 330, tablet: 420, desktop: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (budgets.isEmpty)
                        Text(
                          'No budgets yet. Add one below.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: context.rFont(12),
                          ),
                        ),
                      for (final budget in budgets)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${budget.category} · ${formatCurrency(budget.monthlyLimit)}',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.rFont(13),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(financeValueProvider.notifier)
                                      .removeCategoryBudget(budget.category);
                                  if (!mounted) {
                                    return;
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: context.rIcon(18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(
                        color: AppColors.muted.withValues(alpha: 0.2),
                        height: context.rs(24),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                      SizedBox(height: context.rs(10)),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monthly limit',
                        ),
                      ),
                      SizedBox(height: context.rs(10)),
                      Text(
                        'Warn at ${(warningThreshold * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: context.rFont(12),
                        ),
                      ),
                      Slider(
                        value: warningThreshold,
                        min: 0.6,
                        max: 1,
                        divisions: 4,
                        onChanged: (value) {
                          setModalState(() {
                            warningThreshold = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () async {
                    final monthlyLimit =
                        double.tryParse(amountController.text.trim());
                    if (monthlyLimit == null || monthlyLimit <= 0) {
                      return;
                    }

                    await ref
                        .read(financeValueProvider.notifier)
                        .setCategoryBudget(
                          category: selectedCategory,
                          monthlyLimit: monthlyLimit,
                          warningThreshold: warningThreshold,
                        );
                    if (!mounted) {
                      return;
                    }

                    unawaited(HapticFeedbackService.success());
                    amountController.clear();
                    setModalState(() {});
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  Future<void> _openBillsManager() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final bills = ref.read(financeValueProvider).bills;

            return AlertDialog(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: const Text('Bills and Subscriptions'),
              content: SizedBox(
                width: context.rValue(mobile: 330, tablet: 420, desktop: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bills.isEmpty)
                        Text(
                          'No bills tracked yet.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: context.rFont(12),
                          ),
                        ),
                      for (final bill in bills)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bill.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.rFont(13),
                                      ),
                                    ),
                                    Text(
                                      '${formatCurrency(bill.amount)} · due ${shortDate(bill.nextDueAt)}',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: context.rFont(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(financeValueProvider.notifier)
                                      .markBillPaid(bill.id);
                                  if (!mounted) {
                                    return;
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  Icons.check_circle_outline,
                                  size: context.rIcon(18),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(financeValueProvider.notifier)
                                      .deleteBill(bill.id);
                                  if (!mounted) {
                                    return;
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: context.rIcon(18),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () async {
                    await _showAddBillDialog();
                    if (!mounted) {
                      return;
                    }
                    setModalState(() {});
                  },
                  child: const Text('Add bill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddBillDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var dueDate = DateTime.now().add(const Duration(days: 7));
    var recurrence = BillRecurrence.monthly;
    var remindDaysBefore = 3;
    var isSubscription = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: const Text('Add Bill'),
              content: SizedBox(
                width: context.rValue(mobile: 320, tablet: 400, desktop: 440),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      SizedBox(height: context.rs(10)),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      SizedBox(height: context.rs(10)),
                      DropdownButtonFormField<BillRecurrence>(
                        initialValue: recurrence,
                        decoration:
                            const InputDecoration(labelText: 'Recurrence'),
                        items: BillRecurrence.values
                            .map(
                              (item) => DropdownMenuItem<BillRecurrence>(
                                value: item,
                                child: Text(item.name.toUpperCase()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            recurrence = value;
                          });
                        },
                      ),
                      SizedBox(height: context.rs(10)),
                      DropdownButtonFormField<int>(
                        initialValue: remindDaysBefore,
                        decoration: const InputDecoration(
                          labelText: 'Remind before',
                        ),
                        items: const [1, 2, 3, 5, 7]
                            .map(
                              (days) => DropdownMenuItem<int>(
                                value: days,
                                child: Text('$days day(s)'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setModalState(() {
                            remindDaysBefore = value;
                          });
                        },
                      ),
                      SizedBox(height: context.rs(10)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Due: ${shortDate(dueDate)}',
                              style: TextStyle(fontSize: context.rFont(12)),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: dueDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (picked == null) {
                                return;
                              }
                              setModalState(() {
                                dueDate = picked;
                              });
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      SwitchListTile.adaptive(
                        value: isSubscription,
                        title: const Text('Subscription'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setModalState(() {
                            isSubscription = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim());
                    if (name.isEmpty || amount == null || amount <= 0) {
                      return;
                    }

                    await ref.read(financeValueProvider.notifier).upsertBill(
                          FinanceBillEntry(
                            id: generateFinanceTransactionId(),
                            name: name,
                            amount: amount,
                            category: 'Bills',
                            nextDueAt: dueDate,
                            recurrence: recurrence,
                            remindDaysBefore: remindDaysBefore,
                            isSubscription: isSubscription,
                            isActive: true,
                          ),
                        );

                    if (!mounted) {
                      return;
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    unawaited(HapticFeedbackService.success());
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
  }

  Future<void> _openNetWorthManager() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final entries = ref.read(financeValueProvider).netWorthEntries;
            final snapshot = ref.read(financeNetWorthSnapshotProvider);

            return AlertDialog(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: const Text('Net Worth Tracker'),
              content: SizedBox(
                width: context.rValue(mobile: 330, tablet: 420, desktop: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assets ${formatCurrency(snapshot.totalAssets)}',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Liabilities ${formatCurrency(snapshot.totalLiabilities)}',
                        style: TextStyle(
                          color: AppColors.accentPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: context.rs(8)),
                      if (entries.isEmpty)
                        Text(
                          'No entries yet.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: context.rFont(12),
                          ),
                        ),
                      for (final entry in entries.reversed)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.rs(8)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.name} · ${entry.type.name}',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.rFont(13),
                                  ),
                                ),
                              ),
                              Text(
                                formatCurrency(entry.amount),
                                style: TextStyle(
                                  color: entry.type == NetWorthEntryType.asset
                                      ? AppColors.accentGreen
                                      : AppColors.accentPink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(financeValueProvider.notifier)
                                      .deleteNetWorthEntry(entry.id);
                                  if (!mounted) {
                                    return;
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: context.rIcon(18),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () async {
                    await _showAddNetWorthDialog();
                    if (!mounted) {
                      return;
                    }
                    setModalState(() {});
                  },
                  child: const Text('Add entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddNetWorthDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var entryType = NetWorthEntryType.asset;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: const Text('Add Net Worth Entry'),
              content: SizedBox(
                width: context.rValue(mobile: 320, tablet: 400, desktop: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: context.rs(10)),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    SizedBox(height: context.rs(10)),
                    DropdownButtonFormField<NetWorthEntryType>(
                      initialValue: entryType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: NetWorthEntryType.values
                          .map(
                            (type) => DropdownMenuItem<NetWorthEntryType>(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          entryType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim());
                    if (name.isEmpty || amount == null || amount <= 0) {
                      return;
                    }

                    await ref
                        .read(financeValueProvider.notifier)
                        .upsertNetWorthEntry(
                          NetWorthEntry(
                            id: generateFinanceTransactionId(),
                            name: name,
                            type: entryType,
                            amount: amount,
                            recordedAt: DateTime.now(),
                          ),
                        );

                    if (!mounted) {
                      return;
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    unawaited(HapticFeedbackService.success());
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
  }

  Widget _buildChoiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: selected,
      label: Text(label, style: TextStyle(fontSize: context.rFont(12))),
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.background : AppColors.text,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    FinanceState state, {
    required String label,
    required FinanceDateRange range,
    required ValueChanged<FinanceDateRange> onTap,
  }) {
    final selected = state.dateRange == range;
    return InkWell(
      onTap: () => onTap(range),
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
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: context.rFont(12),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action can be undone from the snackbar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
