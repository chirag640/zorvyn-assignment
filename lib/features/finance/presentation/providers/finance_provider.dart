import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/datasources/finance_supabase_data_source.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/finance_repository_impl.dart';

enum FinanceTransactionType { expense, income }

enum FinanceDateRange { all, thisWeek, thisMonth, last30Days }

enum FinanceSyncStatus { idle, syncing, error }

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final double amount;
  final FinanceTransactionType type;
  final String category;
  final DateTime date;
  final DateTime updatedAt;
  final String? note;

  FinanceTransaction copyWith({
    String? id,
    double? amount,
    FinanceTransactionType? type,
    String? category,
    DateTime? date,
    DateTime? updatedAt,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'note': note,
    };
  }

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    final parsedDate =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

    return FinanceTransaction(
      id: (json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: FinanceTransactionType.values.firstWhere(
        (item) => item.name == (json['type'] as String? ?? 'expense'),
        orElse: () => FinanceTransactionType.expense,
      ),
      category: (json['category'] as String?) ?? 'Other',
      date: parsedDate,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? parsedDate,
      note: json['note'] as String?,
    );
  }
}

class FinanceState {
  const FinanceState({
    this.transactions = const [],
    this.searchQuery = '',
    this.filterType,
    this.filterCategory,
    this.dateRange = FinanceDateRange.all,
    this.isLoading = false,
    this.chartPulseToken = 0,
    this.weeklySavingsTarget = 50,
    this.weeklySpendLimit = 120,
    this.monthlySavingsGoal = 500,
    this.dailySpendLimit = 25,
    this.goalSettingsUpdatedAtIso = '',
    this.syncStatus = FinanceSyncStatus.idle,
    this.pendingSyncCount = 0,
    this.syncError,
  });

  final List<FinanceTransaction> transactions;
  final String searchQuery;
  final FinanceTransactionType? filterType;
  final String? filterCategory;
  final FinanceDateRange dateRange;
  final bool isLoading;
  final int chartPulseToken;
  final double weeklySavingsTarget;
  final double weeklySpendLimit;
  final double monthlySavingsGoal;
  final double dailySpendLimit;
  final String goalSettingsUpdatedAtIso;
  final FinanceSyncStatus syncStatus;
  final int pendingSyncCount;
  final String? syncError;

  FinanceState copyWith({
    List<FinanceTransaction>? transactions,
    String? searchQuery,
    FinanceTransactionType? filterType,
    bool clearFilterType = false,
    String? filterCategory,
    bool clearFilterCategory = false,
    FinanceDateRange? dateRange,
    bool? isLoading,
    int? chartPulseToken,
    double? weeklySavingsTarget,
    double? weeklySpendLimit,
    double? monthlySavingsGoal,
    double? dailySpendLimit,
    String? goalSettingsUpdatedAtIso,
    FinanceSyncStatus? syncStatus,
    int? pendingSyncCount,
    String? syncError,
    bool clearSyncError = false,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterCategory:
          clearFilterCategory ? null : (filterCategory ?? this.filterCategory),
      dateRange: dateRange ?? this.dateRange,
      isLoading: isLoading ?? this.isLoading,
      chartPulseToken: chartPulseToken ?? this.chartPulseToken,
      weeklySavingsTarget: weeklySavingsTarget ?? this.weeklySavingsTarget,
      weeklySpendLimit: weeklySpendLimit ?? this.weeklySpendLimit,
      monthlySavingsGoal: monthlySavingsGoal ?? this.monthlySavingsGoal,
      dailySpendLimit: dailySpendLimit ?? this.dailySpendLimit,
      goalSettingsUpdatedAtIso:
          goalSettingsUpdatedAtIso ?? this.goalSettingsUpdatedAtIso,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier(this._repository)
      : super(const FinanceState(isLoading: true)) {
    _startBackgroundSyncRetry();
    _load();
  }

  final FinanceRepository _repository;
  static const Duration _backgroundSyncRetryInterval = Duration(seconds: 15);
  Timer? _backgroundSyncRetryTimer;

  void _startBackgroundSyncRetry() {
    _backgroundSyncRetryTimer?.cancel();
    _backgroundSyncRetryTimer = Timer.periodic(
      _backgroundSyncRetryInterval,
      (_) {
        if (!mounted) {
          return;
        }

        final shouldRetryInBackground = state.pendingSyncCount > 0 &&
            state.syncStatus != FinanceSyncStatus.syncing;

        if (!shouldRetryInBackground) {
          return;
        }

        unawaited(_syncWith(() => _repository.syncPendingOperations()));
      },
    );
  }

  @override
  void dispose() {
    _backgroundSyncRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loaded = await _repository.load();
      final transactions = loaded.transactions
          .map(FinanceTransaction.fromJson)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(
        isLoading: false,
        transactions: transactions,
        weeklySavingsTarget: loaded.goalSettings.weeklySavingsTarget,
        weeklySpendLimit: loaded.goalSettings.weeklySpendLimit,
        monthlySavingsGoal: loaded.goalSettings.monthlySavingsGoal,
        dailySpendLimit: loaded.goalSettings.dailySpendLimit,
        goalSettingsUpdatedAtIso: loaded.goalSettings.updatedAt,
      );

      _applySyncResult(loaded.syncResult);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        syncStatus: FinanceSyncStatus.error,
        syncError: error.toString(),
      );
    }
  }

  Future<void> _persistLocalSnapshot() {
    return _repository.saveLocalSnapshot(
      transactions: state.transactions.map((tx) => tx.toJson()).toList(),
      goalSettings: _goalSettingsFromState(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  Future<void> retryPendingSync() async {
    await _syncWith(() => _repository.syncPendingOperations());
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setFilterType(FinanceTransactionType? type) {
    state = state.copyWith(
      filterType: type,
      clearFilterType: type == null,
    );
  }

  void setFilterCategory(String? category) {
    state = state.copyWith(
      filterCategory: category,
      clearFilterCategory: category == null,
    );
  }

  void setDateRange(FinanceDateRange range) {
    state = state.copyWith(dateRange: range);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearFilterType: true,
      clearFilterCategory: true,
      dateRange: FinanceDateRange.all,
    );
  }

  Future<void> updateGoalSettings({
    required double weeklySavingsTarget,
    required double weeklySpendLimit,
    required double monthlySavingsGoal,
    required double dailySpendLimit,
  }) async {
    final updatedAt = DateTime.now().toIso8601String();

    state = state.copyWith(
      weeklySavingsTarget: max(1, weeklySavingsTarget),
      weeklySpendLimit: max(1, weeklySpendLimit),
      monthlySavingsGoal: max(1, monthlySavingsGoal),
      dailySpendLimit: max(1, dailySpendLimit),
      goalSettingsUpdatedAtIso: updatedAt,
      chartPulseToken: state.chartPulseToken + 1,
    );

    await _persistLocalSnapshot();
    await _syncWith(
      () => _repository.queueUpsertGoalSettings(_goalSettingsFromState()),
    );
  }

  Future<void> addTransaction({
    required double amount,
    required FinanceTransactionType type,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final now = DateTime.now();

    final tx = FinanceTransaction(
      id: now.microsecondsSinceEpoch.toString(),
      amount: amount,
      type: type,
      category: category,
      date: date ?? now,
      updatedAt: now,
      note: note,
    );

    final next = [tx, ...state.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(
      transactions: next,
      chartPulseToken: state.chartPulseToken + 1,
    );

    await _persistLocalSnapshot();
    await _syncWith(() => _repository.queueUpsertTransaction(tx.toJson()));
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required FinanceTransactionType type,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final now = DateTime.now();

    FinanceTransaction? updatedTransaction;
    final updated = state.transactions.map((tx) {
      if (tx.id != id) {
        return tx;
      }

      final nextTransaction = tx.copyWith(
        amount: amount,
        type: type,
        category: category,
        note: note,
        date: date ?? tx.date,
        updatedAt: now,
      );
      updatedTransaction = nextTransaction;
      return nextTransaction;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(
      transactions: updated,
      chartPulseToken: state.chartPulseToken + 1,
    );

    await _persistLocalSnapshot();
    if (updatedTransaction != null) {
      await _syncWith(
        () => _repository.queueUpsertTransaction(updatedTransaction!.toJson()),
      );
    }
  }

  Future<FinanceTransaction?> deleteTransaction(String id) async {
    FinanceTransaction? deleted;
    final retained = <FinanceTransaction>[];

    for (final tx in state.transactions) {
      if (tx.id == id) {
        deleted = tx;
      } else {
        retained.add(tx);
      }
    }

    if (deleted == null) {
      return null;
    }

    state = state.copyWith(
      transactions: retained,
      chartPulseToken: state.chartPulseToken + 1,
    );

    await _persistLocalSnapshot();
    await _syncWith(() => _repository.queueDeleteTransaction(id));
    return deleted;
  }

  Future<void> restoreTransaction(FinanceTransaction tx) async {
    final restoredTransaction = tx.copyWith(updatedAt: DateTime.now());
    final restored = [restoredTransaction, ...state.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(
      transactions: restored,
      chartPulseToken: state.chartPulseToken + 1,
    );

    await _persistLocalSnapshot();
    await _syncWith(
      () => _repository.queueUpsertTransaction(restoredTransaction.toJson()),
    );
  }

  Future<void> _syncWith(
    Future<FinanceSyncResult> Function() operation,
  ) async {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      syncStatus: FinanceSyncStatus.syncing,
      clearSyncError: true,
    );

    try {
      final result = await operation();
      if (!mounted) {
        return;
      }
      _applySyncResult(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        syncStatus: FinanceSyncStatus.error,
        syncError: error.toString(),
      );
    }
  }

  void _applySyncResult(FinanceSyncResult result) {
    final status = result.hasError
        ? FinanceSyncStatus.error
        : result.pendingOperations > 0
            ? FinanceSyncStatus.syncing
            : FinanceSyncStatus.idle;

    state = state.copyWith(
      syncStatus: status,
      pendingSyncCount: result.pendingOperations,
      syncError: result.errorMessage,
      clearSyncError: !result.hasError,
    );
  }

  FinanceGoalSettingsData _goalSettingsFromState() {
    return FinanceGoalSettingsData(
      weeklySavingsTarget: state.weeklySavingsTarget,
      weeklySpendLimit: state.weeklySpendLimit,
      monthlySavingsGoal: state.monthlySavingsGoal,
      dailySpendLimit: state.dailySpendLimit,
      updatedAt: state.goalSettingsUpdatedAtIso.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : state.goalSettingsUpdatedAtIso,
    );
  }
}

final financeSupabaseDataSourceProvider =
    Provider<FinanceSupabaseDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return FinanceSupabaseDataSource(client);
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl(
    localStorage: ref.watch(localStorageProvider),
    remoteDataSource: ref.watch(financeSupabaseDataSourceProvider),
  );
});

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier(ref.watch(financeRepositoryProvider));
});

final filteredTransactionsProvider = Provider<List<FinanceTransaction>>((ref) {
  final state = ref.watch(financeProvider);
  final query = state.searchQuery.trim().toLowerCase();

  bool matchesRange(DateTime date) {
    final now = DateTime.now();
    switch (state.dateRange) {
      case FinanceDateRange.all:
        return true;
      case FinanceDateRange.thisWeek:
        final weekStart =
            DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return !date.isBefore(weekStart);
      case FinanceDateRange.thisMonth:
        return date.year == now.year && date.month == now.month;
      case FinanceDateRange.last30Days:
        final lower = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30));
        return !date.isBefore(lower);
    }
  }

  return state.transactions.where((tx) {
    final matchesQuery = query.isEmpty ||
        tx.category.toLowerCase().contains(query) ||
        (tx.note?.toLowerCase().contains(query) ?? false) ||
        tx.amount.toStringAsFixed(2).contains(query);

    final matchesType = state.filterType == null || tx.type == state.filterType;
    final matchesCategory =
        state.filterCategory == null || tx.category == state.filterCategory;

    return matchesQuery &&
        matchesType &&
        matchesCategory &&
        matchesRange(tx.date);
  }).toList();
});

final hasActiveFinanceFiltersProvider = Provider<bool>((ref) {
  final state = ref.watch(financeProvider);
  return state.searchQuery.trim().isNotEmpty ||
      state.filterType != null ||
      state.filterCategory != null ||
      state.dateRange != FinanceDateRange.all;
});

final financeSummaryProvider = Provider<FinanceSummary>((ref) {
  final state = ref.watch(financeProvider);
  return FinanceSummary.fromState(state);
});

class FinanceSummary {
  const FinanceSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.todayExpense,
    required this.sparkline,
    required this.weeklySavingsProgress,
    required this.weeklySpendProgress,
    required this.monthlyGoalProgress,
    required this.currentStreak,
    required this.categorySpending,
    required this.weeklyExpenses,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.currentWeekExpense,
    required this.previousWeekExpense,
    required this.weeklyDeltaPercent,
    required this.currentMonthExpense,
    required this.previousMonthExpense,
    required this.monthlyDeltaPercent,
    required this.mostFrequentType,
    required this.mostFrequentTypeCount,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double todayExpense;
  final List<double> sparkline;
  final double weeklySavingsProgress;
  final double weeklySpendProgress;
  final double monthlyGoalProgress;
  final int currentStreak;
  final Map<String, double> categorySpending;
  final List<double> weeklyExpenses;
  final String topCategoryName;
  final double topCategoryAmount;
  final double currentWeekExpense;
  final double previousWeekExpense;
  final double weeklyDeltaPercent;
  final double currentMonthExpense;
  final double previousMonthExpense;
  final double monthlyDeltaPercent;
  final FinanceTransactionType mostFrequentType;
  final int mostFrequentTypeCount;

  static FinanceSummary fromState(FinanceState state) {
    final transactions = state.transactions;
    double income = 0;
    double expense = 0;
    final now = DateTime.now();

    for (final tx in transactions) {
      if (tx.type == FinanceTransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    double todayExpense = 0;
    final categorySpending = <String, double>{};

    for (final tx in transactions) {
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (tx.type == FinanceTransactionType.expense && txDay == today) {
        todayExpense += tx.amount;
      }
      if (tx.type == FinanceTransactionType.expense &&
          tx.date.month == now.month &&
          tx.date.year == now.year) {
        categorySpending[tx.category] =
            (categorySpending[tx.category] ?? 0) + tx.amount;
      }
    }

    final sparkline = _last7DaysExpense(transactions, now);
    final weeklyExpenses = _currentMonthWeeklyExpense(transactions, now);

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = weekStart.subtract(const Duration(milliseconds: 1));

    final weekSavings = _netBetween(transactions, weekStart, now);
    final weeklySpend = _expenseBetween(transactions, weekStart, now);
    final previousWeeklySpend =
        _expenseBetween(transactions, previousWeekStart, previousWeekEnd);

    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd =
        currentMonthStart.subtract(const Duration(milliseconds: 1));

    final monthlySavings = _netBetween(transactions, currentMonthStart, now);
    final currentMonthExpense =
        _expenseBetween(transactions, currentMonthStart, now);
    final previousMonthExpense =
        _expenseBetween(transactions, previousMonthStart, previousMonthEnd);

    final streak = _calculateLowSpendStreak(
      transactions,
      dailyLimit: state.dailySpendLimit,
    );

    String topCategoryName = 'N/A';
    double topCategoryAmount = 0;
    if (categorySpending.isNotEmpty) {
      final top = categorySpending.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topCategoryName = top.key;
      topCategoryAmount = top.value;
    }

    int expenseCount = 0;
    int incomeCount = 0;
    for (final tx in transactions) {
      if (tx.type == FinanceTransactionType.expense) {
        expenseCount++;
      } else {
        incomeCount++;
      }
    }

    final mostFrequentType = incomeCount > expenseCount
        ? FinanceTransactionType.income
        : FinanceTransactionType.expense;
    final mostFrequentTypeCount = max(incomeCount, expenseCount);

    return FinanceSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      todayExpense: todayExpense,
      sparkline: sparkline,
      weeklySavingsProgress:
          _safeProgress(weekSavings, state.weeklySavingsTarget),
      weeklySpendProgress: _safeProgress(weeklySpend, state.weeklySpendLimit),
      monthlyGoalProgress:
          _safeProgress(monthlySavings, state.monthlySavingsGoal),
      currentStreak: streak,
      categorySpending: categorySpending,
      weeklyExpenses: weeklyExpenses,
      topCategoryName: topCategoryName,
      topCategoryAmount: topCategoryAmount,
      currentWeekExpense: weeklySpend,
      previousWeekExpense: previousWeeklySpend,
      weeklyDeltaPercent: _deltaPercent(weeklySpend, previousWeeklySpend),
      currentMonthExpense: currentMonthExpense,
      previousMonthExpense: previousMonthExpense,
      monthlyDeltaPercent:
          _deltaPercent(currentMonthExpense, previousMonthExpense),
      mostFrequentType: mostFrequentType,
      mostFrequentTypeCount: mostFrequentTypeCount,
    );
  }

  static List<double> _last7DaysExpense(
      List<FinanceTransaction> transactions, DateTime now) {
    return List<double>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      double value = 0;
      for (final tx in transactions) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (tx.type == FinanceTransactionType.expense && txDay == day) {
          value += tx.amount;
        }
      }
      return value;
    });
  }

  static List<double> _currentMonthWeeklyExpense(
      List<FinanceTransaction> transactions, DateTime now) {
    final weeks = List<double>.filled(4, 0);
    for (final tx in transactions) {
      if (tx.type != FinanceTransactionType.expense ||
          tx.date.month != now.month ||
          tx.date.year != now.year) {
        continue;
      }
      final bucket = min(3, ((tx.date.day - 1) / 7).floor());
      weeks[bucket] += tx.amount;
    }
    return weeks;
  }

  static double _expenseBetween(
      List<FinanceTransaction> transactions, DateTime start, DateTime end) {
    double total = 0;
    for (final tx in transactions) {
      if (tx.date.isBefore(start) || tx.date.isAfter(end)) {
        continue;
      }
      if (tx.type == FinanceTransactionType.expense) {
        total += tx.amount;
      }
    }
    return total;
  }

  static double _netBetween(
      List<FinanceTransaction> transactions, DateTime start, DateTime end) {
    double total = 0;
    for (final tx in transactions) {
      if (tx.date.isBefore(start) || tx.date.isAfter(end)) {
        continue;
      }
      total +=
          tx.type == FinanceTransactionType.income ? tx.amount : -tx.amount;
    }
    return total;
  }

  static int _calculateLowSpendStreak(List<FinanceTransaction> transactions,
      {required double dailyLimit}) {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      double spent = 0;

      for (final tx in transactions) {
        final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (tx.type == FinanceTransactionType.expense && txDay == day) {
          spent += tx.amount;
        }
      }

      if (spent <= dailyLimit) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  static double _safeProgress(double value, double target) {
    if (target <= 0) {
      return 0;
    }
    return (value / target).clamp(0, 1);
  }

  static double _deltaPercent(double current, double previous) {
    if (previous <= 0) {
      return current <= 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }
}
