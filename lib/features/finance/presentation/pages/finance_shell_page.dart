import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_responsive.dart';
import '../providers/finance_provider.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/goals_tab.dart';
import '../widgets/insights_tab.dart';
import '../widgets/transactions_tab.dart';

class FinanceShellPage extends ConsumerStatefulWidget {
  const FinanceShellPage({super.key});

  @override
  ConsumerState<FinanceShellPage> createState() => _FinanceShellPageState();
}

class _FinanceShellPageState extends ConsumerState<FinanceShellPage>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _fabOpen = false;
  DateTime? _lastResumeRefreshAt;

  static const Duration _resumeRefreshThrottle = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    final now = DateTime.now();
    final last = _lastResumeRefreshAt;
    if (last != null && now.difference(last) < _resumeRefreshThrottle) {
      return;
    }

    _lastResumeRefreshAt = now;
    unawaited(ref.read(financeProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);

    final pages = <Widget>[
      DashboardTab(onOpenAdd: _openAddSheet),
      TransactionsTab(onEditTransaction: _openEditSheet),
      const GoalsTab(),
      const InsightsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(index: _index, children: pages),
            ),
            Positioned(
              top: context.rs(8),
              left: context.rs(12),
              right: context.rs(60),
              child: _syncBanner(context, financeState),
            ),
            Positioned(
              top: context.rs(6),
              right: context.rs(12),
              child: PopupMenuButton<_ShellAction>(
                tooltip: 'More',
                onSelected: _onQuickAction,
                color: AppColors.background,
                surfaceTintColor: Colors.transparent,
                elevation: 1,
                offset: Offset(0, context.rs(44)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rRadius(14)),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem<_ShellAction>(
                    value: _ShellAction.profile,
                    child: Text('Profile'),
                  ),
                  PopupMenuItem<_ShellAction>(
                    value: _ShellAction.settings,
                    child: Text('Settings'),
                  ),
                ],
                child: Container(
                  width: context.rs(40),
                  height: context.rs(40),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(context.rRadius(14)),
                    border: Border.all(
                      color: AppColors.muted.withValues(alpha: 0.18),
                      width: context.rThickness(1),
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: context.rIcon(20),
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        label: 'Add transaction',
        button: true,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 220),
          turns: _fabOpen ? 0.125 : 0,
          child: SizedBox(
            width: context.rs(64),
            height: context.rs(64),
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: const CircleBorder(),
              onPressed: _openAddSheet,
              child: Icon(Icons.add, size: context.rIcon(30)),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _bottomNav(),
      ),
    );
  }

  Widget _syncBanner(BuildContext context, FinanceState state) {
    final hasPendingSync = state.pendingSyncCount > 0;
    final isError = state.syncStatus == FinanceSyncStatus.error;
    final isSyncing = state.syncStatus == FinanceSyncStatus.syncing;

    if (!hasPendingSync && !isError && !isSyncing) {
      return const SizedBox.shrink();
    }

    final message = isError
        ? (state.syncError?.trim().isNotEmpty == true
            ? state.syncError!.trim()
            : 'Sync failed. Tap retry to sync your latest changes.')
        : hasPendingSync
            ? isSyncing
                ? 'Syncing ${state.pendingSyncCount} '
                    '${state.pendingSyncCount == 1 ? 'change' : 'changes'}...'
                : 'Pending ${state.pendingSyncCount} '
                    '${state.pendingSyncCount == 1 ? 'change' : 'changes'}.'
            : 'Syncing latest updates...';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key:
            ValueKey<String>('sync-banner-$isError-$hasPendingSync-$isSyncing'),
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(10),
          vertical: context.rs(6),
        ),
        decoration: BoxDecoration(
          color: isError
              ? AppColors.accentPink.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(context.rRadius(12)),
          border: Border.all(
            color: isError
                ? AppColors.accentPink.withValues(alpha: 0.4)
                : AppColors.muted.withValues(alpha: 0.16),
            width: context.rThickness(1),
          ),
        ),
        child: Row(
          children: [
            if (isError)
              Icon(
                Icons.error_outline_rounded,
                size: context.rIcon(14),
                color: AppColors.text,
              )
            else if (isSyncing)
              SizedBox(
                width: context.rs(12),
                height: context.rs(12),
                child: CircularProgressIndicator(
                  strokeWidth: context.rThickness(2),
                ),
              )
            else
              Icon(
                Icons.schedule_rounded,
                size: context.rIcon(14),
                color: AppColors.text,
              ),
            SizedBox(width: context.rs(8)),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: context.rFont(11),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isError || (hasPendingSync && !isSyncing)) ...[
              SizedBox(width: context.rs(6)),
              TextButton(
                onPressed: () {
                  ref.read(financeProvider.notifier).retryPendingSync();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(6),
                    vertical: context.rs(2),
                  ),
                  minimumSize: Size(context.rs(42), context.rs(28)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: context.rFont(11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final items = <_NavItem>[
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
      const _NavItem(icon: Icons.track_changes_rounded, label: 'Goals'),
      const _NavItem(icon: Icons.insights_rounded, label: 'Insights'),
    ];

    return BottomAppBar(
      color: AppColors.background,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: context.rs(8),
      child: SizedBox(
        height: context.rs(74),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: i == 2
                    ? Padding(
                        padding: EdgeInsets.only(left: context.rs(26)),
                        child: _BottomNavButton(
                          item: items[i],
                          selected: _index == i,
                          onTap: () => setState(() => _index = i),
                        ),
                      )
                    : i == 1
                        ? Padding(
                            padding: EdgeInsets.only(right: context.rs(26)),
                            child: _BottomNavButton(
                              item: items[i],
                              selected: _index == i,
                              onTap: () => setState(() => _index = i),
                            ),
                          )
                        : _BottomNavButton(
                            item: items[i],
                            selected: _index == i,
                            onTap: () => setState(() => _index = i),
                          ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    setState(() {
      _fabOpen = true;
    });

    final result = await _openTransactionSheet();

    if (!mounted) {
      return;
    }

    setState(() {
      _fabOpen = false;
    });

    await _persistSheetResult(result);
  }

  Future<void> _openEditSheet(FinanceTransaction transaction) async {
    final result = await _openTransactionSheet(initialTransaction: transaction);
    if (!mounted) {
      return;
    }

    await _persistSheetResult(result);
  }

  Future<AddTransactionResult?> _openTransactionSheet({
    FinanceTransaction? initialTransaction,
  }) {
    final isEditing = initialTransaction != null;

    return showModalBottomSheet<AddTransactionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(context.rRadius(28))),
      ),
      builder: (context) {
        final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsetsBottom),
          child: FractionallySizedBox(
            heightFactor: context.rValue(
              mobile: 0.82,
              tablet: 0.74,
              desktop: 0.64,
            ),
            child: AddTransactionSheet(
              initialTransaction: initialTransaction,
              submitLabel: isEditing ? 'Update' : 'Save',
              onSave: (value) {
                Navigator.of(context).pop(value);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _persistSheetResult(AddTransactionResult? result) async {
    if (result == null) {
      return;
    }

    if (result.transactionId != null) {
      await ref.read(financeProvider.notifier).updateTransaction(
            id: result.transactionId!,
            amount: result.amount,
            type: result.type,
            category: result.category,
            note: result.note,
            date: result.date,
          );
      return;
    }

    await ref.read(financeProvider.notifier).addTransaction(
          amount: result.amount,
          type: result.type,
          category: result.category,
          note: result.note,
          date: result.date,
        );
  }

  void _onQuickAction(_ShellAction action) {
    switch (action) {
      case _ShellAction.profile:
        Navigator.of(context).pushNamed(AppRouter.profile);
        return;
      case _ShellAction.settings:
        Navigator.of(context).pushNamed(AppRouter.settings);
        return;
    }
  }
}

enum _ShellAction {
  profile,
  settings,
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.rRadius(16)),
      onTap: onTap,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: context.rIcon(20),
                color: selected ? AppColors.primary : AppColors.muted,
              ),
              SizedBox(height: context.rs(2)),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.muted,
                  fontSize: context.rFont(10),
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
