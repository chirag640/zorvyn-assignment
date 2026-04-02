import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/finance/data/repositories/finance_repository.dart';
import 'package:frontend/features/finance/presentation/providers/finance_provider.dart';
import 'package:frontend/features/finance/presentation/widgets/add_transaction_sheet.dart';
import 'package:frontend/features/finance/presentation/widgets/dashboard_tab.dart';

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

FinanceLoadResult _loadResult({
  List<Map<String, dynamic>> transactions = const [],
}) {
  return FinanceLoadResult(
    transactions: transactions,
    goalSettings: FinanceGoalSettingsData.defaults(),
    syncResult: const FinanceSyncResult(pendingOperations: 0),
  );
}

DateTime _day(int dayOffset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
}

void main() {
  testWidgets('AddTransactionSheet enables save only after positive amount',
      (tester) async {
    AddTransactionResult? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTransactionSheet(
            onSave: (result) {
              saved = result;
            },
          ),
        ),
      ),
    );

    final saveButtonFinder = find.widgetWithText(FilledButton, 'Save');
    expect(saveButtonFinder, findsOneWidget);

    FilledButton saveButton = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNull);

    final oneKeyFinder = find
        .descendant(
          of: find.byType(GridView),
          matching: find.text('1'),
        )
        .first;
    await tester.tap(oneKeyFinder);
    await tester.pump();

    saveButton = tester.widget<FilledButton>(saveButtonFinder);
    expect(saveButton.onPressed, isNotNull);

    await tester.ensureVisible(saveButtonFinder);
    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved?.amount, 1);
    expect(saved?.type, FinanceTransactionType.expense);
  });

  testWidgets('DashboardTab renders summary cards from provider state',
      (tester) async {
    final now = _day(0);
    final repository = _FakeFinanceRepository(
      loadResult: _loadResult(
        transactions: [
          {
            'id': 'income-1',
            'amount': 1000,
            'type': 'income',
            'category': 'Salary',
            'date': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
          {
            'id': 'expense-1',
            'amount': 250,
            'type': 'expense',
            'category': 'Food',
            'date': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: DashboardTab(
            onOpenAdd: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.textContaining('750.00'), findsOneWidget);
    expect(find.textContaining('1,000.00'), findsWidgets);
    expect(find.textContaining('250.00'), findsWidgets);
  });

  testWidgets('Dashboard chart pulse updates after transaction save',
      (tester) async {
    final now = _day(0);
    final repository = _FakeFinanceRepository(
      loadResult: _loadResult(
        transactions: [
          {
            'id': 'seed-1',
            'amount': 120,
            'type': 'expense',
            'category': 'Food',
            'date': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: [
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: DashboardTab(
            onOpenAdd: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);

    await container.read(financeProvider.notifier).addTransaction(
          amount: 55,
          type: FinanceTransactionType.expense,
          category: 'Transport',
          date: now,
        );

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
  });

  testWidgets('Dashboard balance text animates on balance change',
      (tester) async {
    final now = _day(0);
    final repository = _FakeFinanceRepository(
      loadResult: _loadResult(
        transactions: [
          {
            'id': 'income-seed',
            'amount': 200,
            'type': 'income',
            'category': 'Salary',
            'date': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ],
      ),
    );

    final container = ProviderContainer(
      overrides: [
        financeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: DashboardTab(
            onOpenAdd: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AnimatedSwitcher), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('balance-200.00')),
      findsOneWidget,
    );

    await container.read(financeProvider.notifier).addTransaction(
          amount: 50,
          type: FinanceTransactionType.expense,
          category: 'Food',
          date: now,
        );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('balance-150.00')),
      findsOneWidget,
    );
  });
}
