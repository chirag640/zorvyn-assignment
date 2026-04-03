import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zorvyn_finance/core/network/network_info.dart';
import 'package:zorvyn_finance/core/providers/app_providers.dart';
import 'package:zorvyn_finance/core/storage/local_storage.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/presentation/pages/finance_shell_page.dart';
import 'package:zorvyn_finance/features/finance/presentation/providers/finance_provider.dart';

class _FakeFinanceRepository implements FinanceRepository {
  const _FakeFinanceRepository();

  @override
  Future<FinanceLoadResult> load() async {
    return FinanceLoadResult(
      transactions: const [],
      goalSettings: FinanceGoalSettingsData.defaults(),
      syncResult: const FinanceSyncResult(pendingOperations: 0),
    );
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

Future<LocalStorage> _testLocalStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.getInstance();
  await storage.clear();
  return storage;
}

Widget _buildShellWithOverrides({
  required MediaQueryData mediaQueryData,
  required LocalStorage localStorage,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      financeRepositoryProvider
          .overrideWithValue(const _FakeFinanceRepository()),
      networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
      financeRealtimeChangesProvider.overrideWith(
        (ref) => const Stream<void>.empty(),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: mediaQueryData,
        child: const FinanceShellPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('Finance shell exposes semantic label for add transaction action',
      (tester) async {
    final localStorage = await _testLocalStorage();
    await tester.pumpWidget(
      _buildShellWithOverrides(
        mediaQueryData: const MediaQueryData(),
        localStorage: localStorage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Add transaction'), findsWidgets);

    final fabSize = tester.getSize(find.byType(FloatingActionButton));
    expect(fabSize.width, greaterThanOrEqualTo(48));
    expect(fabSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('Finance shell remains stable at larger text scale',
      (tester) async {
    final localStorage = await _testLocalStorage();
    await tester.pumpWidget(
      _buildShellWithOverrides(
        mediaQueryData: const MediaQueryData(
          textScaler: TextScaler.linear(1.3),
        ),
        localStorage: localStorage,
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
  });
}
