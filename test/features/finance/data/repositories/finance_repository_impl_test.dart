import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/core/storage/local_storage.dart';
import 'package:zorvyn_finance/features/finance/data/datasources/finance_supabase_data_source.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository.dart';
import 'package:zorvyn_finance/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _FakeFinanceSupabaseDataSource extends FinanceSupabaseDataSource {
  _FakeFinanceSupabaseDataSource({
    this.remoteTransactions = const [],
    this.remoteGoalSettings,
  }) : super(_MockSupabaseClient());

  final List<Map<String, dynamic>> remoteTransactions;
  final Map<String, dynamic>? remoteGoalSettings;

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    return remoteTransactions;
  }

  @override
  Future<Map<String, dynamic>?> fetchGoalSettings() async {
    return remoteGoalSettings;
  }

  @override
  Future<void> upsertTransaction(Map<String, dynamic> transaction) async {}

  @override
  Future<void> deleteTransaction(String transactionId) async {}

  @override
  Future<void> upsertGoalSettings({
    required double weeklySavingsTarget,
    required double weeklySpendLimit,
    required double monthlySavingsGoal,
    required double dailySpendLimit,
    required String updatedAt,
  }) async {}
}

const _transactionsKey = 'finance_transactions_v1';
const _settingsKey = 'finance_goal_settings_v1';

Future<LocalStorage> _freshLocalStorage() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final local = await LocalStorage.getInstance();
  await local.clear();
  return local;
}

Map<String, dynamic> _tx({
  required String id,
  required double amount,
  required String updatedAt,
}) {
  return {
    'id': id,
    'amount': amount,
    'type': 'expense',
    'category': 'Food',
    'date': '2026-04-02T10:00:00.000Z',
    'updatedAt': updatedAt,
  };
}

Map<String, dynamic> _goal({
  required double weeklySavingsTarget,
  required String updatedAt,
}) {
  return {
    'weeklySavingsTarget': weeklySavingsTarget,
    'weeklySpendLimit': 120,
    'monthlySavingsGoal': 500,
    'dailySpendLimit': 25,
    'updatedAt': updatedAt,
  };
}

void main() {
  group('FinanceRepositoryImpl merge/conflict behavior', () {
    test('keeps local transaction when local updatedAt is newer', () async {
      final localStorage = await _freshLocalStorage();
      await localStorage.setJsonList(
        _transactionsKey,
        [
          _tx(
            id: 't1',
            amount: 10,
            updatedAt: '2026-04-02T11:00:00.000Z',
          ),
        ],
      );

      final remoteDataSource = _FakeFinanceSupabaseDataSource(
        remoteTransactions: [
          _tx(
            id: 't1',
            amount: 50,
            updatedAt: '2026-04-02T10:00:00.000Z',
          ),
        ],
      );

      final repository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.load();

      expect(result.transactions, hasLength(1));
      expect(result.transactions.first['id'], 't1');
      expect(result.transactions.first['amount'], 10.0);
    });

    test('uses remote transaction when remote updatedAt is newer', () async {
      final localStorage = await _freshLocalStorage();
      await localStorage.setJsonList(
        _transactionsKey,
        [
          _tx(
            id: 't1',
            amount: 10,
            updatedAt: '2026-04-02T09:00:00.000Z',
          ),
        ],
      );

      final remoteDataSource = _FakeFinanceSupabaseDataSource(
        remoteTransactions: [
          _tx(
            id: 't1',
            amount: 50,
            updatedAt: '2026-04-02T12:00:00.000Z',
          ),
        ],
      );

      final repository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.load();

      expect(result.transactions, hasLength(1));
      expect(result.transactions.first['id'], 't1');
      expect(result.transactions.first['amount'], 50.0);
    });

    test('uses newer remote goal settings over local values', () async {
      final localStorage = await _freshLocalStorage();
      await localStorage.setJson(
        _settingsKey,
        _goal(
          weeklySavingsTarget: 10,
          updatedAt: '2026-04-01T09:00:00.000Z',
        ),
      );

      final remoteDataSource = _FakeFinanceSupabaseDataSource(
        remoteGoalSettings: {
          'weeklySavingsTarget': 99,
          'weeklySpendLimit': 240,
          'monthlySavingsGoal': 800,
          'dailySpendLimit': 40,
          'updatedAt': '2026-04-02T12:00:00.000Z',
        },
      );

      final repository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: remoteDataSource,
      );

      final result = await repository.load();

      expect(result.goalSettings.weeklySavingsTarget, 99);
      expect(result.goalSettings.weeklySpendLimit, 240);
      expect(result.goalSettings.monthlySavingsGoal, 800);
      expect(result.goalSettings.dailySpendLimit, 40);
    });

    test('isolates local snapshots by user scope id', () async {
      final localStorage = await _freshLocalStorage();

      final userARepository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: null,
        userScopeId: 'user-a',
      );

      await userARepository.saveLocalSnapshot(
        transactions: [
          _tx(
            id: 'user-a-tx',
            amount: 25,
            updatedAt: '2026-04-02T11:00:00.000Z',
          ),
        ],
        goalSettings: FinanceGoalSettingsData.defaults(),
      );

      final userBRepository = FinanceRepositoryImpl(
        localStorage: localStorage,
        remoteDataSource: null,
        userScopeId: 'user-b',
      );

      final userBData = await userBRepository.load();

      expect(userBData.transactions, isEmpty);
      expect(userBData.goalSettings.weeklySavingsTarget, 50);
    });
  });
}
