import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zorvyn_finance/core/network/network_info.dart';
import 'package:zorvyn_finance/core/providers/app_providers.dart';
import 'package:zorvyn_finance/core/storage/local_storage.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_value_provider.dart';

class _FakeFinanceRepository implements FinanceRepository {
  _FakeFinanceRepository({required this.loadResult});

  final FinanceLoadResult loadResult;

  @override
  Future<FinanceLoadResult> load() async {
    return loadResult;
  }

  @override
  Future<void> saveLocalSnapshot({
    required List<Map<String, dynamic>> transactions,
    required FinanceGoalSettingsData goalSettings,
  }) async {}

  @override
  Future<FinanceSyncResult> queueUpsertTransaction(
    Map<String, dynamic> transaction,
  ) async {
    return const FinanceSyncResult(pendingOperations: 0);
  }

  @override
  Future<FinanceSyncResult> queueDeleteTransaction(String transactionId) async {
    return const FinanceSyncResult(pendingOperations: 0);
  }

  @override
  Future<FinanceSyncResult> queueUpsertGoalSettings(
    FinanceGoalSettingsData goalSettings,
  ) async {
    return const FinanceSyncResult(pendingOperations: 0);
  }

  @override
  Future<FinanceSyncResult> syncPendingOperations() async {
    return const FinanceSyncResult(pendingOperations: 0);
  }
}

class _FakeNetworkInfo extends NetworkInfo {
  _FakeNetworkInfo() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream<bool>.empty();
}

class _TestFinanceValueNotifier extends FinanceValueNotifier {
  _TestFinanceValueNotifier(LocalStorage storage) : super(storage, null);
}

Future<ProviderContainer> _createContainer({
  required List<Map<String, dynamic>> transactions,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.getInstance();
  await storage.clear();

  final repository = _FakeFinanceRepository(
    loadResult: FinanceLoadResult(
      transactions: transactions,
      goalSettings: FinanceGoalSettingsData.defaults(),
      syncResult: const FinanceSyncResult(pendingOperations: 0),
    ),
  );

  return ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      financeRepositoryProvider.overrideWithValue(repository),
      networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
      financeRealtimeChangesProvider.overrideWith(
        (ref) => const Stream<void>.empty(),
      ),
      financeValueProvider.overrideWith(
        (ref) => _TestFinanceValueNotifier(storage),
      ),
    ],
  );
}

Map<String, dynamic> _txJson({
  required String id,
  required double amount,
  required String type,
  required String category,
  required DateTime date,
}) {
  return {
    'id': id,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
    'updatedAt': date.toIso8601String(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects recurring transaction patterns from monthly history', () async {
    final now = DateTime.now();
    final container = await _createContainer(
      transactions: [
        _txJson(
          id: 'salary-1',
          amount: 4000,
          type: 'income',
          category: 'Salary',
          date: DateTime(now.year, now.month - 2, 1),
        ),
        _txJson(
          id: 'salary-2',
          amount: 4000,
          type: 'income',
          category: 'Salary',
          date: DateTime(now.year, now.month - 1, 1),
        ),
        _txJson(
          id: 'salary-3',
          amount: 4000,
          type: 'income',
          category: 'Salary',
          date: DateTime(now.year, now.month, 1),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(financeProvider.notifier).refresh();

    final patterns = container.read(financeRecurringPatternsProvider);
    expect(patterns, isNotEmpty);
    expect(patterns.first.category, 'Salary');
    expect(patterns.first.type, FinanceTransactionType.income);
    expect(patterns.first.averageIntervalDays, inInclusiveRange(27, 33));
  });

  test('creates budget warning when monthly spend crosses threshold', () async {
    final now = DateTime.now();
    final container = await _createContainer(
      transactions: [
        _txJson(
          id: 'groceries-1',
          amount: 450,
          type: 'expense',
          category: 'Groceries',
          date: DateTime(now.year, now.month, 3),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(financeProvider.notifier).refresh();
    await container.read(financeValueProvider.notifier).setCategoryBudget(
          category: 'Groceries',
          monthlyLimit: 500,
          warningThreshold: 0.8,
        );

    final warnings = container.read(financeBudgetWarningsProvider);
    expect(warnings, hasLength(1));
    expect(warnings.first.category, 'Groceries');
    expect(warnings.first.percent, closeTo(0.9, 0.001));
  });

  test('filters due bills based on reminder window', () async {
    final now = DateTime.now();
    final container = await _createContainer(transactions: const []);
    addTearDown(container.dispose);

    await container.read(financeValueProvider.notifier).upsertBill(
          FinanceBillEntry(
            id: 'bill-1',
            name: 'Internet',
            amount: 50,
            category: 'Bills',
            nextDueAt: now.add(const Duration(days: 2)),
            recurrence: BillRecurrence.monthly,
            remindDaysBefore: 3,
            isSubscription: true,
            isActive: true,
          ),
        );
    await container.read(financeValueProvider.notifier).upsertBill(
          FinanceBillEntry(
            id: 'bill-2',
            name: 'Gym',
            amount: 30,
            category: 'Bills',
            nextDueAt: now.add(const Duration(days: 8)),
            recurrence: BillRecurrence.monthly,
            remindDaysBefore: 3,
            isSubscription: true,
            isActive: true,
          ),
        );

    final dueBills = container.read(financeDueBillsProvider);
    expect(dueBills, hasLength(1));
    expect(dueBills.first.name, 'Internet');
  });

  test('computes net worth snapshot from assets and liabilities', () async {
    final now = DateTime.now();
    final container = await _createContainer(transactions: const []);
    addTearDown(container.dispose);

    await container.read(financeValueProvider.notifier).upsertNetWorthEntry(
          NetWorthEntry(
            id: 'asset-1',
            name: 'Savings',
            type: NetWorthEntryType.asset,
            amount: 12000,
            recordedAt: now.subtract(const Duration(days: 30)),
          ),
        );
    await container.read(financeValueProvider.notifier).upsertNetWorthEntry(
          NetWorthEntry(
            id: 'liability-1',
            name: 'Loan',
            type: NetWorthEntryType.liability,
            amount: 4000,
            recordedAt: now,
          ),
        );

    final snapshot = container.read(financeNetWorthSnapshotProvider);
    expect(snapshot.totalAssets, 12000);
    expect(snapshot.totalLiabilities, 4000);
    expect(snapshot.netWorth, 8000);
  });

  test('provides keyword-based suggestion with confidence metadata', () {
    final suggestion = suggestFinanceCategoryWithConfidence(
      note: 'Uber to office',
      type: FinanceTransactionType.expense,
      amount: 18,
      history: const <FinanceTransaction>[],
      recurringPatterns: const <RecurringTransactionPattern>[],
    );

    expect(suggestion, isNotNull);
    expect(suggestion!.category, 'Transport');
    expect(suggestion.source, FinanceCategorySuggestionSource.keyword);
    expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
  });

  test('cashflow forecast exposes contribution breakdowns', () async {
    final now = DateTime.now();
    final container = await _createContainer(
      transactions: [
        _txJson(
          id: 'inc-1',
          amount: 1800,
          type: 'income',
          category: 'Salary',
          date: now.subtract(const Duration(days: 5)),
        ),
        _txJson(
          id: 'exp-1',
          amount: 600,
          type: 'expense',
          category: 'Groceries',
          date: now.subtract(const Duration(days: 3)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(financeProvider.notifier).refresh();
    await container.read(financeValueProvider.notifier).upsertBill(
          FinanceBillEntry(
            id: 'bill-forecast-1',
            name: 'Utilities',
            amount: 120,
            category: 'Bills',
            nextDueAt: now.add(const Duration(days: 2)),
            recurrence: BillRecurrence.monthly,
            remindDaysBefore: 5,
            isSubscription: false,
            isActive: true,
          ),
        );

    final forecast = container.read(financeCashflowForecastProvider);

    expect(forecast.billsContribution7Days, closeTo(-120, 0.001));
    expect(
      forecast.projectedBalance7Days,
      closeTo(
        forecast.currentBalance +
            forecast.trendContribution7Days +
            forecast.recurringContribution7Days +
            forecast.billsContribution7Days,
        0.001,
      ),
    );
  });
}
