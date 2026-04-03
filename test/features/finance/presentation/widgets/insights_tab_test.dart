import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/core/network/network_info.dart';
import 'package:zorvyn_finance/core/providers/app_providers.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_provider.dart';
import 'package:zorvyn_finance/features/finance/presentation/widgets/insights_tab.dart';

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

DateTime _dateMonthsAgo(int monthsAgo, int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - monthsAgo, day, 10, 0);
}

void main() {
  testWidgets('Insights month picker updates displayed period metrics',
      (tester) async {
    final repository = _FakeFinanceRepository(
      loadResult: FinanceLoadResult(
        transactions: [
          {
            'id': 'current-food',
            'amount': 120,
            'type': 'expense',
            'category': 'Food',
            'date': _dateMonthsAgo(0, 7).toIso8601String(),
            'updatedAt': _dateMonthsAgo(0, 7).toIso8601String(),
          },
          {
            'id': 'last-bills',
            'amount': 280,
            'type': 'expense',
            'category': 'Bills',
            'date': _dateMonthsAgo(1, 12).toIso8601String(),
            'updatedAt': _dateMonthsAgo(1, 12).toIso8601String(),
          },
          {
            'id': 'older-transport',
            'amount': 360,
            'type': 'expense',
            'category': 'Transport',
            'date': _dateMonthsAgo(2, 15).toIso8601String(),
            'updatedAt': _dateMonthsAgo(2, 15).toIso8601String(),
          },
        ],
        goalSettings: FinanceGoalSettingsData.defaults(),
        syncResult: const FinanceSyncResult(pendingOperations: 0),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(repository),
          networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InsightsTab()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
        find.textContaining('Selected period (This month):'), findsOneWidget);
    expect(find.textContaining('Food •'), findsOneWidget);

    await tester.tap(find.text('Last month'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Selected period (Last month):'), findsOneWidget);
    expect(find.textContaining('Bills •'), findsOneWidget);

    await tester.tap(find.text('2 mo ago'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Selected period (2 mo ago):'), findsOneWidget);
    expect(find.textContaining('Transport •'), findsOneWidget);
  });
}
