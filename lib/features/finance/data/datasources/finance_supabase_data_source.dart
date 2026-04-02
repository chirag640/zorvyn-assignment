import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceSupabaseDataSource {
  FinanceSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const String _transactionsTable = 'finance_transactions';
  static const String _goalSettingsTable = 'finance_goal_settings';

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final userId = _userId;
    if (userId == null) {
      return const [];
    }

    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('user_id', userId)
        .order('occurred_at', ascending: false);

    final rows = (response as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return rows.map(_mapTransaction).toList(growable: false);
  }

  Future<void> upsertTransaction(Map<String, dynamic> transaction) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    await _client.from(_transactionsTable).upsert(
      {
        'id': transaction['id'],
        'user_id': userId,
        'amount': transaction['amount'],
        'type': transaction['type'],
        'category': transaction['category'],
        'note': transaction['note'],
        'occurred_at': transaction['date'],
        'updated_at':
            transaction['updatedAt'] ?? DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    await _client
        .from(_transactionsTable)
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>?> fetchGoalSettings() async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }

    final response = await _client
        .from(_goalSettingsTable)
        .select(
          'weekly_savings_target,weekly_spend_limit,monthly_savings_goal,daily_spend_limit,updated_at',
        )
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return {
      'weeklySavingsTarget':
          (response['weekly_savings_target'] as num?)?.toDouble() ?? 50,
      'weeklySpendLimit':
          (response['weekly_spend_limit'] as num?)?.toDouble() ?? 120,
      'monthlySavingsGoal':
          (response['monthly_savings_goal'] as num?)?.toDouble() ?? 500,
      'dailySpendLimit':
          (response['daily_spend_limit'] as num?)?.toDouble() ?? 25,
      'updatedAt': (response['updated_at'] as String?) ?? '',
    };
  }

  Future<void> upsertGoalSettings({
    required double weeklySavingsTarget,
    required double weeklySpendLimit,
    required double monthlySavingsGoal,
    required double dailySpendLimit,
    required String updatedAt,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    await _client.from(_goalSettingsTable).upsert(
      {
        'user_id': userId,
        'weekly_savings_target': weeklySavingsTarget,
        'weekly_spend_limit': weeklySpendLimit,
        'monthly_savings_goal': monthlySavingsGoal,
        'daily_spend_limit': dailySpendLimit,
        'updated_at': updatedAt,
      },
      onConflict: 'user_id',
    );
  }

  Map<String, dynamic> _mapTransaction(Map<String, dynamic> row) {
    final occurredAt = DateTime.tryParse(row['occurred_at'] as String? ?? '') ??
        DateTime.now();

    return {
      'id': (row['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      'amount': (row['amount'] as num?)?.toDouble() ?? 0,
      'type': (row['type'] as String? ?? 'expense').toLowerCase(),
      'category': (row['category'] as String?) ?? 'Other',
      'date': occurredAt.toIso8601String(),
      'note': row['note'] as String?,
      'updatedAt':
          (row['updated_at'] as String?) ?? occurredAt.toIso8601String(),
    };
  }
}
