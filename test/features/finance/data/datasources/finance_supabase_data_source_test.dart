import 'package:flutter_test/flutter_test.dart';
import 'package:zorvyn_finance/features/finance/data/datasources/finance_supabase_data_source.dart';

void main() {
  group('FinanceSupabaseDataSource row mapping', () {
    test('mapTransactionRow maps remote fields to app model shape', () {
      final row = <String, dynamic>{
        'id': 'tx-123',
        'amount': 42,
        'type': 'INCOME',
        'category': 'Salary',
        'occurred_at': '2026-04-02T10:00:00.000Z',
        'note': 'April payout',
        'updated_at': '2026-04-02T10:05:00.000Z',
      };

      final mapped = FinanceSupabaseDataSource.mapTransactionRow(row);

      expect(mapped['id'], 'tx-123');
      expect(mapped['amount'], 42.0);
      expect(mapped['type'], 'income');
      expect(mapped['category'], 'Salary');
      expect(mapped['date'], '2026-04-02T10:00:00.000Z');
      expect(mapped['note'], 'April payout');
      expect(mapped['updatedAt'], '2026-04-02T10:05:00.000Z');
    });

    test('mapTransactionRow falls back safely when fields are missing', () {
      final fallbackNow = DateTime.utc(2026, 4, 2, 11, 30);
      final row = <String, dynamic>{
        'amount': null,
      };

      final mapped = FinanceSupabaseDataSource.mapTransactionRow(
        row,
        nowProvider: () => fallbackNow,
      );

      expect(mapped['id'], fallbackNow.microsecondsSinceEpoch.toString());
      expect(mapped['amount'], 0.0);
      expect(mapped['type'], 'expense');
      expect(mapped['category'], 'Other');
      expect(mapped['date'], fallbackNow.toIso8601String());
      expect(mapped['updatedAt'], fallbackNow.toIso8601String());
    });

    test('mapGoalSettingsRow maps snake_case and applies defaults', () {
      final row = <String, dynamic>{
        'weekly_savings_target': 120,
        'weekly_spend_limit': 240.5,
        // monthly_savings_goal intentionally omitted
        'daily_spend_limit': 40,
        'updated_at': '2026-04-02T09:00:00.000Z',
      };

      final mapped = FinanceSupabaseDataSource.mapGoalSettingsRow(row);

      expect(mapped['weeklySavingsTarget'], 120.0);
      expect(mapped['weeklySpendLimit'], 240.5);
      expect(mapped['monthlySavingsGoal'], 500.0);
      expect(mapped['dailySpendLimit'], 40.0);
      expect(mapped['updatedAt'], '2026-04-02T09:00:00.000Z');
    });
  });
}
