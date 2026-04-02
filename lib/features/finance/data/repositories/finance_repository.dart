class FinanceGoalSettingsData {
  const FinanceGoalSettingsData({
    required this.weeklySavingsTarget,
    required this.weeklySpendLimit,
    required this.monthlySavingsGoal,
    required this.dailySpendLimit,
    required this.updatedAt,
  });

  final double weeklySavingsTarget;
  final double weeklySpendLimit;
  final double monthlySavingsGoal;
  final double dailySpendLimit;
  final String updatedAt;

  static FinanceGoalSettingsData defaults() {
    return FinanceGoalSettingsData(
      weeklySavingsTarget: 50,
      weeklySpendLimit: 120,
      monthlySavingsGoal: 500,
      dailySpendLimit: 25,
      updatedAt: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklySavingsTarget': weeklySavingsTarget,
      'weeklySpendLimit': weeklySpendLimit,
      'monthlySavingsGoal': monthlySavingsGoal,
      'dailySpendLimit': dailySpendLimit,
      'updatedAt': updatedAt,
    };
  }

  factory FinanceGoalSettingsData.fromJson(Map<String, dynamic> json) {
    return FinanceGoalSettingsData(
      weeklySavingsTarget:
          (json['weeklySavingsTarget'] as num?)?.toDouble() ?? 50,
      weeklySpendLimit: (json['weeklySpendLimit'] as num?)?.toDouble() ?? 120,
      monthlySavingsGoal:
          (json['monthlySavingsGoal'] as num?)?.toDouble() ?? 500,
      dailySpendLimit: (json['dailySpendLimit'] as num?)?.toDouble() ?? 25,
      updatedAt: (json['updatedAt'] as String?)?.trim() ?? '',
    );
  }
}

class FinanceSyncResult {
  const FinanceSyncResult({
    required this.pendingOperations,
    this.errorMessage,
  });

  final int pendingOperations;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
}

class FinanceLoadResult {
  const FinanceLoadResult({
    required this.transactions,
    required this.goalSettings,
    required this.syncResult,
  });

  final List<Map<String, dynamic>> transactions;
  final FinanceGoalSettingsData goalSettings;
  final FinanceSyncResult syncResult;
}

abstract class FinanceRepository {
  Future<FinanceLoadResult> load();

  Future<void> saveLocalSnapshot({
    required List<Map<String, dynamic>> transactions,
    required FinanceGoalSettingsData goalSettings,
  });

  Future<FinanceSyncResult> queueUpsertTransaction(
    Map<String, dynamic> transaction,
  );

  Future<FinanceSyncResult> queueDeleteTransaction(String transactionId);

  Future<FinanceSyncResult> queueUpsertGoalSettings(
    FinanceGoalSettingsData goalSettings,
  );

  Future<FinanceSyncResult> syncPendingOperations();
}
