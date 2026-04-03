import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:zorvyn_finance/core/storage/local_storage.dart';
import 'package:zorvyn_finance/features/finance/data/datasources/finance_supabase_data_source.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_provider.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _RecordingFinanceSupabaseDataSource extends FinanceSupabaseDataSource {
  _RecordingFinanceSupabaseDataSource() : super(_MockSupabaseClient());

  final Map<String, Map<String, dynamic>> _remoteTransactionsById =
      <String, Map<String, dynamic>>{};
  Map<String, dynamic>? _remoteGoalSettings;

  final List<Map<String, dynamic>> upsertedTransactions =
      <Map<String, dynamic>>[];
  final List<String> deletedTransactionIds = <String>[];
  final List<Map<String, dynamic>> upsertedGoalSettingsPayloads =
      <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    return _remoteTransactionsById.values.toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchGoalSettings() async {
    return _remoteGoalSettings;
  }

  @override
  Future<void> upsertTransaction(Map<String, dynamic> transaction) async {
    final normalized = Map<String, dynamic>.from(transaction);
    upsertedTransactions.add(normalized);
    final id = (normalized['id'] ?? '').toString();
    if (id.isNotEmpty) {
      _remoteTransactionsById[id] = normalized;
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    deletedTransactionIds.add(transactionId);
    _remoteTransactionsById.remove(transactionId);
  }

  @override
  Future<void> upsertGoalSettings({
    required double weeklySavingsTarget,
    required double weeklySpendLimit,
    required double monthlySavingsGoal,
    required double dailySpendLimit,
    required String updatedAt,
  }) async {
    final payload = <String, dynamic>{
      'weeklySavingsTarget': weeklySavingsTarget,
      'weeklySpendLimit': weeklySpendLimit,
      'monthlySavingsGoal': monthlySavingsGoal,
      'dailySpendLimit': dailySpendLimit,
      'updatedAt': updatedAt,
    };

    upsertedGoalSettingsPayloads.add(payload);
    _remoteGoalSettings = payload;
  }
}

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

class _SequencedFinanceRepository extends _FakeFinanceRepository {
  _SequencedFinanceRepository({
    required List<FinanceLoadResult> loadResults,
  })  : _loadResults = List<FinanceLoadResult>.from(loadResults),
        super(
          loadResult: loadResults.first,
        );

  final List<FinanceLoadResult> _loadResults;
  int _loadIndex = 0;

  @override
  Future<FinanceLoadResult> load() async {
    final index =
        _loadIndex < _loadResults.length ? _loadIndex : _loadResults.length - 1;
    _loadIndex += 1;
    return _loadResults[index];
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

Future<LocalStorage> _freshLocalStorage() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final localStorage = await LocalStorage.getInstance();
  await localStorage.clear();
  return localStorage;
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

    test('refreshes from remote change stream events', () async {
      final remoteChanges = StreamController<void>.broadcast();
      addTearDown(remoteChanges.close);

      final repository = _SequencedFinanceRepository(
        loadResults: [
          _loadResult(
            transactions: [
              {
                'id': 'initial',
                'amount': 10,
                'type': 'expense',
                'category': 'Food',
                'date': _day(-1).toIso8601String(),
                'updatedAt': _day(-1).toIso8601String(),
              },
            ],
          ),
          _loadResult(
            transactions: [
              {
                'id': 'updated',
                'amount': 80,
                'type': 'income',
                'category': 'Salary',
                'date': _day(0).toIso8601String(),
                'updatedAt': _day(0).toIso8601String(),
              },
            ],
          ),
        ],
      );

      final notifier = FinanceNotifier(
        repository,
        remoteChanges: remoteChanges.stream,
      );
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      expect(notifier.state.transactions.first.id, 'initial');

      remoteChanges.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _settleNotifierLoad();

      expect(notifier.state.transactions.first.id, 'updated');
      expect(notifier.state.transactions.first.amount, 80);
    });

    test(
        'integration smoke syncs add/edit/delete and goal update to supabase datasource',
        () async {
      final localStorage = await _freshLocalStorage();
      final remoteDataSource = _RecordingFinanceSupabaseDataSource();
      final repository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: remoteDataSource,
        userScopeId: 'integration-user',
      );

      final notifier = FinanceNotifier(repository);
      addTearDown(notifier.dispose);
      await _settleNotifierLoad();

      await notifier.addTransaction(
        amount: 80,
        type: FinanceTransactionType.expense,
        category: 'Food',
        note: 'Dinner',
        date: _day(0),
      );

      final created = notifier.state.transactions.first;
      expect(remoteDataSource.upsertedTransactions, hasLength(1));
      expect(remoteDataSource.upsertedTransactions.first['id'], created.id);

      await notifier.updateTransaction(
        id: created.id,
        amount: 95,
        type: FinanceTransactionType.expense,
        category: 'Dining',
        note: 'Dinner update',
        date: _day(0),
      );

      expect(remoteDataSource.upsertedTransactions, hasLength(2));
      expect(remoteDataSource.upsertedTransactions.last['amount'], 95.0);
      expect(remoteDataSource.upsertedTransactions.last['category'], 'Dining');

      await notifier.updateGoalSettings(
        weeklySavingsTarget: 120,
        weeklySpendLimit: 200,
        monthlySavingsGoal: 900,
        dailySpendLimit: 35,
      );

      expect(remoteDataSource.upsertedGoalSettingsPayloads, hasLength(1));
      expect(
        remoteDataSource
            .upsertedGoalSettingsPayloads.first['weeklySavingsTarget'],
        120.0,
      );

      final deleted = await notifier.deleteTransaction(created.id);
      expect(deleted, isNotNull);
      expect(remoteDataSource.deletedTransactionIds, [created.id]);
      expect(notifier.state.transactions, isEmpty);
      expect(notifier.state.pendingSyncCount, 0);
      expect(notifier.state.syncStatus, FinanceSyncStatus.idle);
    });

    test('persists transaction state across notifier restarts', () async {
      final localStorage = await _freshLocalStorage();
      final repository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: null,
        userScopeId: 'restart-user',
      );

      final notifier1 = FinanceNotifier(repository);
      await _settleNotifierLoad();
      await notifier1.addTransaction(
        amount: 40,
        type: FinanceTransactionType.expense,
        category: 'Transport',
        note: 'Cab',
        date: _day(0),
      );
      final transactionId = notifier1.state.transactions.first.id;
      notifier1.dispose();

      final notifier2 = FinanceNotifier(repository);
      await _settleNotifierLoad();
      expect(notifier2.state.transactions, hasLength(1));
      expect(notifier2.state.transactions.first.id, transactionId);
      expect(notifier2.state.transactions.first.amount, 40);

      await notifier2.updateTransaction(
        id: transactionId,
        amount: 55,
        type: FinanceTransactionType.expense,
        category: 'Fuel',
        note: 'Cab + fuel',
      );
      notifier2.dispose();

      final notifier3 = FinanceNotifier(repository);
      await _settleNotifierLoad();
      expect(notifier3.state.transactions, hasLength(1));
      expect(notifier3.state.transactions.first.id, transactionId);
      expect(notifier3.state.transactions.first.amount, 55);
      expect(notifier3.state.transactions.first.category, 'Fuel');

      await notifier3.deleteTransaction(transactionId);
      notifier3.dispose();

      final notifier4 = FinanceNotifier(repository);
      await _settleNotifierLoad();
      expect(notifier4.state.transactions, isEmpty);
      notifier4.dispose();
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
