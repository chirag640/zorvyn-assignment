import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import 'finance_ui_helpers.dart';

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({
    super.key,
    required this.onEditTransaction,
  });

  final ValueChanged<FinanceTransaction> onEditTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final hasActiveFilters = ref.watch(hasActiveFinanceFiltersProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(16),
            context.rs(14),
            context.rs(16),
            context.rs(8),
          ),
          child: TextField(
            onChanged: (value) =>
                ref.read(financeProvider.notifier).setSearchQuery(value),
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
                      onPressed: () =>
                          ref.read(financeProvider.notifier).setSearchQuery(''),
                      icon: Icon(Icons.close, size: context.rIcon(18)),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.rRadius(16)),
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
                          context.rs(8),
                          context.rs(16),
                          context.rs(124),
                        ),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.rs(8)),
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
                                    BorderRadius.circular(context.rRadius(20)),
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
                                  BorderRadius.circular(context.rRadius(20)),
                              onTap: () => onEditTransaction(tx),
                              child: Container(
                                padding: EdgeInsets.all(context.rs(14)),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    context.rRadius(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: context.rs(40),
                                      height: context.rs(40),
                                      decoration: BoxDecoration(
                                        color: ui.color,
                                        borderRadius: BorderRadius.circular(
                                          context.rRadius(12),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        ui.badge,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: context.rFont(12),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: context.rs(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.category,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w700,
                                              fontSize: context.rFont(16),
                                            ),
                                          ),
                                          SizedBox(height: context.rs(2)),
                                          Text(
                                            tx.note ?? shortDate(tx.date),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: context.rFont(13),
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
                                        fontSize: context.rFont(14),
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
