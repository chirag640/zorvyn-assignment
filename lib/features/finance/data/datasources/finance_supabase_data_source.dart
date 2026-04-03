import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/finance_id_generator.dart';

class FinanceSupabaseDataSource {
  FinanceSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const String _transactionsTable = 'finance_transactions';
  static const String _goalSettingsTable = 'finance_goal_settings';
  static const Duration _apiTimeout = Duration(seconds: 12);

  String? get _userId => _client.auth.currentUser?.id;
  String? get currentUserId => _userId;

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final userId = _userId;
    if (userId == null) {
      return const [];
    }

    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('user_id', userId)
        .order('occurred_at', ascending: false)
        .timeout(_apiTimeout);

    final rows = (response as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return rows.map(mapTransactionRow).toList(growable: false);
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
    ).timeout(_apiTimeout);
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
        .eq('user_id', userId)
        .timeout(_apiTimeout);
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
        .maybeSingle()
        .timeout(_apiTimeout);

    if (response == null) {
      return null;
    }

    return mapGoalSettingsRow(response);
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
    ).timeout(_apiTimeout);
  }

  Stream<void> watchUserFinanceChanges() {
    final userId = _userId?.trim();
    if (userId == null || userId.isEmpty) {
      return const Stream<void>.empty();
    }

    late final RealtimeChannel channel;
    late final StreamController<void> controller;
    var hasSubscribed = false;
    controller = StreamController<void>(
      onListen: () {
        final filter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        );

        channel = _client.channel(
          'public:finance_sync:$userId:${DateTime.now().microsecondsSinceEpoch}',
        );

        channel
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: _transactionsTable,
              filter: filter,
              callback: (_) {
                if (!controller.isClosed) {
                  controller.add(null);
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: _goalSettingsTable,
              filter: filter,
              callback: (_) {
                if (!controller.isClosed) {
                  controller.add(null);
                }
              },
            )
            .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (hasSubscribed && !controller.isClosed) {
              controller.add(null);
            }
            hasSubscribed = true;
            return;
          }

          if (!controller.isClosed &&
              (status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.timedOut) &&
              error != null) {
            controller.addError(error);
          }
        });
      },
      onCancel: () async {
        await channel.unsubscribe();
        await _client.removeChannel(channel);
      },
    );

    return controller.stream;
  }

  @visibleForTesting
  static Map<String, dynamic> mapTransactionRow(
    Map<String, dynamic> row, {
    DateTime Function()? nowProvider,
  }) {
    final now = nowProvider?.call() ?? DateTime.now();
    final occurredAt =
        DateTime.tryParse(row['occurred_at'] as String? ?? '') ?? now;

    return {
      'id': normalizeOrGenerateFinanceTransactionId(
        row['id']?.toString(),
        now: now,
      ),
      'amount': (row['amount'] as num?)?.toDouble() ?? 0,
      'type': (row['type'] as String? ?? 'expense').toLowerCase(),
      'category': (row['category'] as String?) ?? 'Other',
      'date': occurredAt.toIso8601String(),
      'note': row['note'] as String?,
      'updatedAt':
          (row['updated_at'] as String?) ?? occurredAt.toIso8601String(),
    };
  }

  @visibleForTesting
  static Map<String, dynamic> mapGoalSettingsRow(Map<String, dynamic> row) {
    return {
      'weeklySavingsTarget':
          (row['weekly_savings_target'] as num?)?.toDouble() ?? 50,
      'weeklySpendLimit':
          (row['weekly_spend_limit'] as num?)?.toDouble() ?? 120,
      'monthlySavingsGoal':
          (row['monthly_savings_goal'] as num?)?.toDouble() ?? 500,
      'dailySpendLimit': (row['daily_spend_limit'] as num?)?.toDouble() ?? 25,
      'updatedAt': (row['updated_at'] as String?) ?? '',
    };
  }
}
