import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_provider.dart';

class _FakeFinanceRepository implements FinanceRepository {
  _FakeFinanceRepository({
    required this.loadResult,
    FinanceSyncResult? operationResult,
    FinanceSyncResult? syncPendingResult,
  })  : _operationResult = operationResult ??
            const FinanceSyncResult(
              pendingOperations: 0,
            ),
        _syncPendingResult = syncPendingResult ??
            const FinanceSyncResult(
              pendingOperations: 0,
            );

  final FinanceLoadResult loadResult;
  final FinanceSyncResult _operationResult;
  final FinanceSyncResult _syncPendingResult;
  int syncPendingOperationsCalls = 0;

  int saveLocalSnapshotCalls = 0;
  List<Map<String, dynamic>> lastSavedTransactions = const [];
  FinanceGoalSettingsData? lastSavedGoalSettings;

  final List<Map<String, dynamic>> queuedUpsertTransactions = [];
  final List<String> queuedDeleteIds = [];
  final List<FinanceGoalSettingsData> queuedGoalSettings = [];

  @override
  Future<FinanceLoadResult> load() async {
    return loadResult;
  }

  @override
  Future<void> saveLocalSnapshot({
    required List<Map<String, dynamic>> transactions,
    required FinanceGoalSettingsData goalSettings,
  }) async {
    saveLocalSnapshotCalls++;
    lastSavedTransactions = transactions;
    lastSavedGoalSettings = goalSettings;
  }

  @override
  Future<FinanceSyncResult> queueUpsertTransaction(
    Map<String, dynamic> transaction,
  ) async {
    queuedUpsertTransactions.add(transaction);
    return _operationResult;
  }

  @override
  Future<FinanceSyncResult> queueDeleteTransaction(String transactionId) async {
    queuedDeleteIds.add(transactionId);
    return _operationResult;
  }

  @override
  Future<FinanceSyncResult> queueUpsertGoalSettings(
    FinanceGoalSettingsData goalSettings,
  ) async {
    queuedGoalSettings.add(goalSettings);
    return _operationResult;
  }

  @override
  Future<FinanceSyncResult> syncPendingOperations() async {
    syncPendingOperationsCalls++;
    return _syncPendingResult;
  }
}

FinanceLoadResult _loadResult({
  List<Map<String, dynamic>> transactions = const [],
  FinanceGoalSettingsData? goalSettings,
  FinanceSyncResult? syncResult,
}) {
  return FinanceLoadResult(
    transactions: transactions,
    goalSettings: goalSettings ?? FinanceGoalSettingsData.defaults(),
    syncResult: syncResult ??
        const FinanceSyncResult(
          pendingOperations: 0,
        ),
  );
}

Future<void> _settleNotifierLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

DateTime _day(int dayOffset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
}

void main() {
  group('FinanceNotifier', () {
    test('loads and sorts transactions by newest date first', () async {
      final repository = _FakeFinanceRepository(
        loadResult: _loadResult(
          transactions: [
            {
              'id': 'older',
              'amount': 10,
              'type': 'expense',
              'category': 'Food',
              'date': _day(-2).toIso8601String(),
              'updatedAt': _day(-2).toIso8601String(),
            },
            {
              'id': 'newer',
              'amount': 20,
              'type': 'income',
              'category': 'Salary',
              'date': _day(-1).toIso8601String(),
              'updatedAt': _day(-1).toIso8601String(),
            },
          ],
        ),
      );

      final notifier = FinanceNotifier(repository);
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      expect(notifier.state.isLoading, isFalse);
      expect(
        notifier.state.transactions.map((item) => item.id).toList(),
        ['newer', 'older'],
      );
    });

    test('addTransaction persists and queues upsert operation', () async {
      final repository = _FakeFinanceRepository(
        loadResult: _loadResult(),
      );

      final notifier = FinanceNotifier(repository);
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      await notifier.addTransaction(
        amount: 42.5,
        type: FinanceTransactionType.expense,
        category: 'Food',
        note: 'Lunch',
        date: _day(0),
      );

      expect(notifier.state.transactions, hasLength(1));
      expect(notifier.state.transactions.first.amount, 42.5);
      expect(notifier.state.transactions.first.category, 'Food');
      expect(repository.saveLocalSnapshotCalls, 1);
      expect(repository.queuedUpsertTransactions, hasLength(1));
      expect(repository.queuedUpsertTransactions.first['amount'], 42.5);
    });

    test('updateGoalSettings clamps values and queues sync', () async {
      final repository = _FakeFinanceRepository(
        loadResult: _loadResult(),
      );

      final notifier = FinanceNotifier(repository);
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      await notifier.updateGoalSettings(
        weeklySavingsTarget: 0,
        weeklySpendLimit: -10,
        monthlySavingsGoal: 0,
        dailySpendLimit: -2,
      );

      expect(notifier.state.weeklySavingsTarget, 1);
      expect(notifier.state.weeklySpendLimit, 1);
      expect(notifier.state.monthlySavingsGoal, 1);
      expect(notifier.state.dailySpendLimit, 1);
      expect(repository.queuedGoalSettings, hasLength(1));
      expect(repository.queuedGoalSettings.first.weeklySavingsTarget, 1);
      expect(repository.queuedGoalSettings.first.dailySpendLimit, 1);
    });

    test('deleteTransaction returns deleted record and queues delete',
        () async {
      final repository = _FakeFinanceRepository(
        loadResult: _loadResult(
          transactions: [
            {
              'id': 'tx-1',
              'amount': 50,
              'type': 'expense',
              'category': 'Bills',
              'date': _day(-1).toIso8601String(),
              'updatedAt': _day(-1).toIso8601String(),
            },
          ],
        ),
      );

      final notifier = FinanceNotifier(repository);
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      final deleted = await notifier.deleteTransaction('tx-1');

      expect(deleted, isNotNull);
      expect(deleted?.id, 'tx-1');
      expect(notifier.state.transactions, isEmpty);
      expect(repository.queuedDeleteIds, ['tx-1']);
    });

    test('retries pending sync when connectivity returns', () async {
      final connectivityController = StreamController<bool>.broadcast();
      addTearDown(connectivityController.close);
      var isOnline = false;

      final repository = _FakeFinanceRepository(
        loadResult: _loadResult(
          syncResult: const FinanceSyncResult(
            pendingOperations: 1,
            errorMessage: 'Offline queue waiting for network',
          ),
        ),
        syncPendingResult: const FinanceSyncResult(pendingOperations: 0),
      );

      final notifier = FinanceNotifier(
        repository,
        isConnected: () async => isOnline,
        connectivityChanges: connectivityController.stream,
      );
      addTearDown(notifier.dispose);

      await _settleNotifierLoad();
      expect(repository.syncPendingOperationsCalls, 0);
      expect(notifier.state.pendingSyncCount, 1);
      expect(notifier.state.syncStatus, FinanceSyncStatus.error);

      isOnline = true;
      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.syncPendingOperationsCalls, 1);
      expect(notifier.state.pendingSyncCount, 0);
      expect(notifier.state.syncStatus, FinanceSyncStatus.idle);
      expect(notifier.state.syncError, isNull);
    });
  });

  group('FinanceSummary', () {
    test('computes totals, top category, and frequent type', () {
      final now = _day(0);
      final state = FinanceState(
        transactions: [
          FinanceTransaction(
            id: 'i1',
            amount: 300,
            type: FinanceTransactionType.income,
            category: 'Salary',
            date: now,
            updatedAt: now,
          ),
          FinanceTransaction(
            id: 'e1',
            amount: 40,
            type: FinanceTransactionType.expense,
            category: 'Food',
            date: now,
            updatedAt: now,
          ),
          FinanceTransaction(
            id: 'e2',
            amount: 20,
            type: FinanceTransactionType.expense,
            category: 'Food',
            date: now,
            updatedAt: now,
          ),
          FinanceTransaction(
            id: 'e3',
            amount: 10,
            type: FinanceTransactionType.expense,
            category: 'Transport',
            date: now,
            updatedAt: now,
          ),
        ],
      );

      final summary = FinanceSummary.fromState(state);

      expect(summary.totalIncome, closeTo(300, 0.001));
      expect(summary.totalExpense, closeTo(70, 0.001));
      expect(summary.balance, closeTo(230, 0.001));
      expect(summary.todayExpense, closeTo(70, 0.001));
      expect(summary.topCategoryName, 'Food');
      expect(summary.topCategoryAmount, closeTo(60, 0.001));
      expect(summary.mostFrequentType, FinanceTransactionType.expense);
      expect(summary.mostFrequentTypeCount, 3);
      expect(summary.sparkline, hasLength(7));
      expect(summary.weeklyExpenses, hasLength(4));
    });

    test('streak breaks when a day exceeds the daily spend limit', () {
      final now = _day(0);
      final yesterday = _day(-1);

      final state = FinanceState(
        dailySpendLimit: 25,
        transactions: [
          FinanceTransaction(
            id: 'today-ok',
            amount: 10,
            type: FinanceTransactionType.expense,
            category: 'Food',
            date: now,
            updatedAt: now,
          ),
          FinanceTransaction(
            id: 'yesterday-break',
            amount: 30,
            type: FinanceTransactionType.expense,
            category: 'Food',
            date: yesterday,
            updatedAt: yesterday,
          ),
        ],
      );

      final summary = FinanceSummary.fromState(state);

      expect(summary.currentStreak, 1);
      expect(summary.currentMonthExpense, greaterThan(0));
      expect(summary.monthlyDeltaPercent, 100);
    });
  });
}
