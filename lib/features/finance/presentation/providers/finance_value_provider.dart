import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/utils/finance_id_generator.dart';
import 'finance_provider.dart';

class RecurringTransactionPattern {
  const RecurringTransactionPattern({
    required this.category,
    required this.type,
    required this.amount,
    required this.occurrences,
    required this.averageIntervalDays,
    required this.confidence,
    required this.nextExpectedDate,
  });

  final String category;
  final FinanceTransactionType type;
  final double amount;
  final int occurrences;
  final int averageIntervalDays;
  final double confidence;
  final DateTime nextExpectedDate;
}

enum FinanceCategorySuggestionSource { keyword, history, recurring }

class FinanceCategorySuggestion {
  const FinanceCategorySuggestion({
    required this.category,
    required this.confidence,
    required this.source,
  });

  final String category;
  final double confidence;
  final FinanceCategorySuggestionSource source;

  String get sourceLabel {
    switch (source) {
      case FinanceCategorySuggestionSource.keyword:
        return 'note keywords';
      case FinanceCategorySuggestionSource.history:
        return 'your history';
      case FinanceCategorySuggestionSource.recurring:
        return 'recurring patterns';
    }
  }
}

class CategoryBudgetLimit {
  const CategoryBudgetLimit({
    required this.category,
    required this.monthlyLimit,
    required this.warningThreshold,
  });

  final String category;
  final double monthlyLimit;
  final double warningThreshold;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
      'warningThreshold': warningThreshold,
    };
  }

  factory CategoryBudgetLimit.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetLimit(
      category: (json['category'] as String?)?.trim() ?? 'Other',
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
      warningThreshold:
          ((json['warningThreshold'] as num?)?.toDouble() ?? 0.8).clamp(0.5, 1),
    );
  }
}

class BudgetWarning {
  const BudgetWarning({
    required this.category,
    required this.spent,
    required this.limit,
    required this.percent,
  });

  final String category;
  final double spent;
  final double limit;
  final double percent;
}

enum BillRecurrence { weekly, monthly, yearly }

class FinanceBillEntry {
  const FinanceBillEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.nextDueAt,
    required this.recurrence,
    required this.remindDaysBefore,
    required this.isSubscription,
    required this.isActive,
    this.notes,
    this.lastPaidAt,
  });

  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime nextDueAt;
  final BillRecurrence recurrence;
  final int remindDaysBefore;
  final bool isSubscription;
  final bool isActive;
  final String? notes;
  final DateTime? lastPaidAt;

  FinanceBillEntry copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    DateTime? nextDueAt,
    BillRecurrence? recurrence,
    int? remindDaysBefore,
    bool? isSubscription,
    bool? isActive,
    String? notes,
    DateTime? lastPaidAt,
  }) {
    return FinanceBillEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      recurrence: recurrence ?? this.recurrence,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      isSubscription: isSubscription ?? this.isSubscription,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'nextDueAt': nextDueAt.toIso8601String(),
      'recurrence': recurrence.name,
      'remindDaysBefore': remindDaysBefore,
      'isSubscription': isSubscription,
      'isActive': isActive,
      'notes': notes,
      'lastPaidAt': lastPaidAt?.toIso8601String(),
    };
  }

  factory FinanceBillEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return FinanceBillEntry(
      id: normalizeOrGenerateFinanceTransactionId(json['id']?.toString()),
      name: (json['name'] as String?)?.trim() ?? 'Bill',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'Bills',
      nextDueAt: DateTime.tryParse(json['nextDueAt'] as String? ?? '') ?? now,
      recurrence: BillRecurrence.values.firstWhere(
        (value) => value.name == (json['recurrence'] as String? ?? 'monthly'),
        orElse: () => BillRecurrence.monthly,
      ),
      remindDaysBefore: (json['remindDaysBefore'] as num?)?.toInt() ?? 3,
      isSubscription: json['isSubscription'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      lastPaidAt: DateTime.tryParse(json['lastPaidAt'] as String? ?? ''),
    );
  }
}

class CashflowForecast {
  const CashflowForecast({
    required this.currentBalance,
    required this.projectedBalance7Days,
    required this.projectedBalance30Days,
    required this.trendContribution7Days,
    required this.trendContribution30Days,
    required this.recurringContribution7Days,
    required this.recurringContribution30Days,
    required this.billsContribution7Days,
    required this.billsContribution30Days,
    required this.expectedIncome7Days,
    required this.expectedExpense7Days,
    required this.expectedIncome30Days,
    required this.expectedExpense30Days,
  });

  final double currentBalance;
  final double projectedBalance7Days;
  final double projectedBalance30Days;
  final double trendContribution7Days;
  final double trendContribution30Days;
  final double recurringContribution7Days;
  final double recurringContribution30Days;
  final double billsContribution7Days;
  final double billsContribution30Days;
  final double expectedIncome7Days;
  final double expectedExpense7Days;
  final double expectedIncome30Days;
  final double expectedExpense30Days;
}

enum NetWorthEntryType { asset, liability }

class NetWorthEntry {
  const NetWorthEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.recordedAt,
  });

  final String id;
  final String name;
  final NetWorthEntryType type;
  final double amount;
  final DateTime recordedAt;

  NetWorthEntry copyWith({
    String? id,
    String? name,
    NetWorthEntryType? type,
    double? amount,
    DateTime? recordedAt,
  }) {
    return NetWorthEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'amount': amount,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory NetWorthEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return NetWorthEntry(
      id: normalizeOrGenerateFinanceTransactionId(json['id']?.toString()),
      name: (json['name'] as String?)?.trim() ?? 'Item',
      type: NetWorthEntryType.values.firstWhere(
        (value) => value.name == (json['type'] as String? ?? 'asset'),
        orElse: () => NetWorthEntryType.asset,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? now,
    );
  }
}

class NetWorthSnapshot {
  const NetWorthSnapshot({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.trendPercent,
    required this.series,
  });

  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double trendPercent;
  final List<double> series;
}

class FinanceValueState {
  const FinanceValueState({
    this.budgets = const <CategoryBudgetLimit>[],
    this.bills = const <FinanceBillEntry>[],
    this.netWorthEntries = const <NetWorthEntry>[],
  });

  final List<CategoryBudgetLimit> budgets;
  final List<FinanceBillEntry> bills;
  final List<NetWorthEntry> netWorthEntries;

  FinanceValueState copyWith({
    List<CategoryBudgetLimit>? budgets,
    List<FinanceBillEntry>? bills,
    List<NetWorthEntry>? netWorthEntries,
  }) {
    return FinanceValueState(
      budgets: budgets ?? this.budgets,
      bills: bills ?? this.bills,
      netWorthEntries: netWorthEntries ?? this.netWorthEntries,
    );
  }
}

class FinanceValueNotifier extends StateNotifier<FinanceValueState> {
  FinanceValueNotifier(
    this._localStorage,
    this._userId,
  ) : super(const FinanceValueState()) {
    _load();
  }

  final LocalStorage _localStorage;
  final String? _userId;

  static const String _budgetKeyBase = 'finance_budgets_v1';
  static const String _billsKeyBase = 'finance_bills_v1';
  static const String _netWorthKeyBase = 'finance_net_worth_v1';

  String get _budgetKey => _scopedKey(_budgetKeyBase);
  String get _billsKey => _scopedKey(_billsKeyBase);
  String get _netWorthKey => _scopedKey(_netWorthKeyBase);

  Future<void> _load() async {
    final budgetJson = _localStorage.getJsonList(_budgetKey) ?? const [];
    final billsJson = _localStorage.getJsonList(_billsKey) ?? const [];
    final netWorthJson = _localStorage.getJsonList(_netWorthKey) ?? const [];

    state = state.copyWith(
      budgets: budgetJson
          .map((item) => CategoryBudgetLimit.fromJson(item))
          .toList(growable: false),
      bills: billsJson
          .map((item) => FinanceBillEntry.fromJson(item))
          .toList(growable: false)
        ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt)),
      netWorthEntries: netWorthJson
          .map((item) => NetWorthEntry.fromJson(item))
          .toList(growable: false)
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)),
    );
  }

  Future<void> _save() async {
    await _localStorage.setJsonList(
      _budgetKey,
      state.budgets.map((item) => item.toJson()).toList(growable: false),
    );
    await _localStorage.setJsonList(
      _billsKey,
      state.bills.map((item) => item.toJson()).toList(growable: false),
    );
    await _localStorage.setJsonList(
      _netWorthKey,
      state.netWorthEntries
          .map((item) => item.toJson())
          .toList(growable: false),
    );
  }

  Future<void> setCategoryBudget({
    required String category,
    required double monthlyLimit,
    double warningThreshold = 0.8,
  }) async {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) {
      return;
    }

    final next = <CategoryBudgetLimit>[
      ...state.budgets.where((item) => item.category != normalizedCategory),
      CategoryBudgetLimit(
        category: normalizedCategory,
        monthlyLimit: monthlyLimit,
        warningThreshold: warningThreshold,
      ),
    ]..sort((a, b) => a.category.compareTo(b.category));

    state = state.copyWith(budgets: next);
    await _save();
  }

  Future<void> removeCategoryBudget(String category) async {
    final next = state.budgets
        .where((item) => item.category != category)
        .toList(growable: false);
    state = state.copyWith(budgets: next);
    await _save();
  }

  Future<void> upsertBill(FinanceBillEntry bill) async {
    final next = <FinanceBillEntry>[
      ...state.bills.where((item) => item.id != bill.id),
      bill,
    ]..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

    state = state.copyWith(bills: next);
    await _save();
  }

  Future<void> deleteBill(String id) async {
    final next = state.bills.where((item) => item.id != id).toList();
    state = state.copyWith(bills: next);
    await _save();
  }

  Future<void> markBillPaid(String id) async {
    final next = state.bills.map((bill) {
      if (bill.id != id) {
        return bill;
      }

      final now = DateTime.now();
      DateTime nextDue;
      switch (bill.recurrence) {
        case BillRecurrence.weekly:
          nextDue = bill.nextDueAt.add(const Duration(days: 7));
          break;
        case BillRecurrence.monthly:
          nextDue = DateTime(
            bill.nextDueAt.year,
            bill.nextDueAt.month + 1,
            bill.nextDueAt.day,
          );
          break;
        case BillRecurrence.yearly:
          nextDue = DateTime(
            bill.nextDueAt.year + 1,
            bill.nextDueAt.month,
            bill.nextDueAt.day,
          );
          break;
      }

      return bill.copyWith(lastPaidAt: now, nextDueAt: nextDue);
    }).toList()
      ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

    state = state.copyWith(bills: next);
    await _save();
  }

  Future<void> upsertNetWorthEntry(NetWorthEntry entry) async {
    final next = <NetWorthEntry>[
      ...state.netWorthEntries.where((item) => item.id != entry.id),
      entry,
    ]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    state = state.copyWith(netWorthEntries: next);
    await _save();
  }

  Future<void> deleteNetWorthEntry(String id) async {
    final next = state.netWorthEntries.where((item) => item.id != id).toList();
    state = state.copyWith(netWorthEntries: next);
    await _save();
  }

  String _scopedKey(String base) {
    final scope = _userId?.trim();
    if (scope == null || scope.isEmpty) {
      return base;
    }

    return '${base}_${scope.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
  }
}

final financeValueProvider =
    StateNotifierProvider<FinanceValueNotifier, FinanceValueState>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  return FinanceValueNotifier(localStorage, userId);
});

final financeRecurringPatternsProvider =
    Provider<List<RecurringTransactionPattern>>((ref) {
  final transactions =
      ref.watch(financeProvider.select((state) => state.transactions));

  final grouped = <String, List<FinanceTransaction>>{};
  for (final tx in transactions) {
    final key =
        '${tx.type.name}:${tx.category}:${tx.amount.toStringAsFixed(2)}';
    grouped.putIfAbsent(key, () => <FinanceTransaction>[]).add(tx);
  }

  final patterns = <RecurringTransactionPattern>[];

  for (final entries in grouped.values) {
    if (entries.length < 3) {
      continue;
    }

    final ordered = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final intervals = <int>[];
    for (var i = 1; i < ordered.length; i++) {
      intervals
          .add(ordered[i].date.difference(ordered[i - 1].date).inDays.abs());
    }

    if (intervals.isEmpty) {
      continue;
    }

    final average = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((value) {
          final delta = value - average;
          return delta * delta;
        }).fold<double>(0, (sum, item) => sum + item) /
        intervals.length;
    final stdDev = sqrt(variance);

    final monthlyScore = max(0, 1 - ((average - 30).abs() / 10));
    final weeklyScore = max(0, 1 - ((average - 7).abs() / 3));
    final biWeeklyScore = max(0, 1 - ((average - 14).abs() / 4));
    final intervalScore = max(monthlyScore, max(weeklyScore, biWeeklyScore));
    final consistencyScore = max(0, 1 - (stdDev / max(average, 1)));

    final confidence = (intervalScore * 0.6) + (consistencyScore * 0.4);
    if (confidence < 0.45) {
      continue;
    }

    final last = ordered.last;
    patterns.add(
      RecurringTransactionPattern(
        category: last.category,
        type: last.type,
        amount: last.amount,
        occurrences: ordered.length,
        averageIntervalDays: average.round(),
        confidence: confidence,
        nextExpectedDate:
            last.date.add(Duration(days: max(1, average.round()))),
      ),
    );
  }

  patterns.sort((a, b) {
    final confidenceCompare = b.confidence.compareTo(a.confidence);
    if (confidenceCompare != 0) {
      return confidenceCompare;
    }
    return b.occurrences.compareTo(a.occurrences);
  });

  return patterns;
});

final financeBudgetWarningsProvider = Provider<List<BudgetWarning>>((ref) {
  final budgets = ref.watch(financeValueProvider).budgets;
  final transactions =
      ref.watch(financeProvider.select((state) => state.transactions));

  if (budgets.isEmpty || transactions.isEmpty) {
    return const <BudgetWarning>[];
  }

  final now = DateTime.now();
  final monthlyExpenseByCategory = <String, double>{};

  for (final tx in transactions) {
    if (tx.type != FinanceTransactionType.expense ||
        tx.date.year != now.year ||
        tx.date.month != now.month) {
      continue;
    }

    monthlyExpenseByCategory[tx.category] =
        (monthlyExpenseByCategory[tx.category] ?? 0) + tx.amount;
  }

  final warnings = <BudgetWarning>[];

  for (final budget in budgets) {
    if (budget.monthlyLimit <= 0) {
      continue;
    }

    final spent = monthlyExpenseByCategory[budget.category] ?? 0;
    final percent = spent / budget.monthlyLimit;
    if (percent >= budget.warningThreshold) {
      warnings.add(BudgetWarning(
        category: budget.category,
        spent: spent,
        limit: budget.monthlyLimit,
        percent: percent,
      ));
    }
  }

  warnings.sort((a, b) => b.percent.compareTo(a.percent));
  return warnings;
});

final financeDueBillsProvider = Provider<List<FinanceBillEntry>>((ref) {
  final bills = ref.watch(financeValueProvider).bills;
  final now = DateTime.now();

  final due = bills.where((bill) {
    if (!bill.isActive) {
      return false;
    }

    final daysUntilDue = bill.nextDueAt.difference(now).inDays;
    return daysUntilDue <= bill.remindDaysBefore;
  }).toList()
    ..sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

  return due;
});

final financeCashflowForecastProvider = Provider<CashflowForecast>((ref) {
  final summary = ref.watch(financeSummaryProvider);
  final transactions =
      ref.watch(financeProvider.select((state) => state.transactions));
  final recurringPatterns = ref.watch(financeRecurringPatternsProvider);
  final bills = ref.watch(financeValueProvider).bills;

  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  double netLast30 = 0;
  for (final tx in transactions) {
    if (tx.date.isBefore(thirtyDaysAgo) || tx.date.isAfter(now)) {
      continue;
    }

    netLast30 +=
        tx.type == FinanceTransactionType.income ? tx.amount : -tx.amount;
  }

  final dailyNet = netLast30 / 30;

  double recurringIncome7 = 0;
  double recurringExpense7 = 0;
  double recurringIncome30 = 0;
  double recurringExpense30 = 0;

  for (final pattern in recurringPatterns.take(12)) {
    final interval = max(1, pattern.averageIntervalDays);
    final occurrences7 = max(0, (7 / interval).floor());
    final occurrences30 = max(0, (30 / interval).floor());

    if (pattern.type == FinanceTransactionType.income) {
      recurringIncome7 += pattern.amount * occurrences7;
      recurringIncome30 += pattern.amount * occurrences30;
    } else {
      recurringExpense7 += pattern.amount * occurrences7;
      recurringExpense30 += pattern.amount * occurrences30;
    }
  }

  double dueBills7 = 0;
  double dueBills30 = 0;
  for (final bill in bills) {
    if (!bill.isActive) {
      continue;
    }

    final days = bill.nextDueAt.difference(now).inDays;
    if (days <= 7) {
      dueBills7 += bill.amount;
    }
    if (days <= 30) {
      dueBills30 += bill.amount;
    }
  }

  final trendContribution7 = dailyNet * 7;
  final trendContribution30 = dailyNet * 30;
  final recurringContribution7 = recurringIncome7 - recurringExpense7;
  final recurringContribution30 = recurringIncome30 - recurringExpense30;
  final billsContribution7 = -dueBills7;
  final billsContribution30 = -dueBills30;

  final expectedIncome7 = max(0.0, trendContribution7) + recurringIncome7;
  final expectedExpense7 = max(
    0.0,
    recurringExpense7 + dueBills7 + max(0.0, -trendContribution7),
  );

  final expectedIncome30 = max(0.0, trendContribution30) + recurringIncome30;
  final expectedExpense30 = max(
    0.0,
    recurringExpense30 + dueBills30 + max(0.0, -trendContribution30),
  );

  final projected7 = summary.balance +
      trendContribution7 +
      recurringContribution7 +
      billsContribution7;
  final projected30 = summary.balance +
      trendContribution30 +
      recurringContribution30 +
      billsContribution30;

  return CashflowForecast(
    currentBalance: summary.balance,
    projectedBalance7Days: projected7,
    projectedBalance30Days: projected30,
    trendContribution7Days: trendContribution7,
    trendContribution30Days: trendContribution30,
    recurringContribution7Days: recurringContribution7,
    recurringContribution30Days: recurringContribution30,
    billsContribution7Days: billsContribution7,
    billsContribution30Days: billsContribution30,
    expectedIncome7Days: expectedIncome7,
    expectedExpense7Days: expectedExpense7,
    expectedIncome30Days: expectedIncome30,
    expectedExpense30Days: expectedExpense30,
  );
});

final financeNetWorthSnapshotProvider = Provider<NetWorthSnapshot>((ref) {
  final entries = ref.watch(financeValueProvider).netWorthEntries;

  if (entries.isEmpty) {
    return const NetWorthSnapshot(
      totalAssets: 0,
      totalLiabilities: 0,
      netWorth: 0,
      trendPercent: 0,
      series: <double>[0, 0, 0],
    );
  }

  final sorted = [...entries]
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  double assets = 0;
  double liabilities = 0;
  for (final entry in sorted) {
    if (entry.type == NetWorthEntryType.asset) {
      assets += entry.amount;
    } else {
      liabilities += entry.amount;
    }
  }

  final netWorth = assets - liabilities;

  final monthlyBuckets = <String, double>{};
  double runningAssets = 0;
  double runningLiabilities = 0;

  for (final entry in sorted) {
    if (entry.type == NetWorthEntryType.asset) {
      runningAssets += entry.amount;
    } else {
      runningLiabilities += entry.amount;
    }

    final key =
        '${entry.recordedAt.year}-${entry.recordedAt.month.toString().padLeft(2, '0')}';
    monthlyBuckets[key] = runningAssets - runningLiabilities;
  }

  final series = monthlyBuckets.values.toList(growable: false);
  final previous = series.length > 1 ? series[series.length - 2] : 0.0;
  final trend = previous == 0
      ? (netWorth == 0 ? 0.0 : 100.0)
      : ((netWorth - previous) / previous.abs()) * 100;

  return NetWorthSnapshot(
    totalAssets: assets,
    totalLiabilities: liabilities,
    netWorth: netWorth,
    trendPercent: trend,
    series: series.length >= 3
        ? series.sublist(series.length - 3)
        : List<double>.from(series),
  );
});

FinanceCategorySuggestion? suggestFinanceCategoryWithConfidence({
  required String note,
  required FinanceTransactionType type,
  required double amount,
  required List<FinanceTransaction> history,
  required List<RecurringTransactionPattern> recurringPatterns,
}) {
  final normalizedNote = note.trim().toLowerCase();
  if (normalizedNote.isEmpty) {
    return _suggestByAmountAndType(type, amount, recurringPatterns);
  }

  const keywordMap = <String, String>{
    'salary': 'Salary',
    'payroll': 'Salary',
    'invoice': 'Freelance',
    'freelance': 'Freelance',
    'uber': 'Transport',
    'taxi': 'Transport',
    'metro': 'Transport',
    'bus': 'Transport',
    'coffee': 'Coffee',
    'starbucks': 'Coffee',
    'grocery': 'Groceries',
    'supermarket': 'Groceries',
    'dinner': 'Dining',
    'lunch': 'Dining',
    'rent': 'Bills',
    'electric': 'Bills',
    'water': 'Bills',
    'internet': 'Bills',
    'amazon': 'Shopping',
    'mall': 'Shopping',
  };

  for (final entry in keywordMap.entries) {
    if (normalizedNote.contains(entry.key)) {
      return FinanceCategorySuggestion(
        category: entry.value,
        confidence: 0.92,
        source: FinanceCategorySuggestionSource.keyword,
      );
    }
  }

  FinanceCategorySuggestion? bestHistorySuggestion;

  for (final tx in history) {
    if (tx.type != type) {
      continue;
    }

    final txNote = tx.note?.trim().toLowerCase();
    if (txNote == null || txNote.isEmpty) {
      continue;
    }

    final isExactMatch = txNote == normalizedNote;
    final isPartialMatch =
        normalizedNote.contains(txNote) || txNote.contains(normalizedNote);
    if (!isExactMatch && !isPartialMatch) {
      continue;
    }

    final baseTextScore = isExactMatch ? 0.95 : 0.82;
    final amountDelta = (tx.amount - amount).abs();
    final amountBaseline = max(1.0, amount.abs());
    final amountScore = (1 - (amountDelta / amountBaseline)).clamp(0.4, 1.0);
    final confidence = ((baseTextScore * 0.75) + (amountScore * 0.25))
        .clamp(0.4, 0.95)
        .toDouble();

    final candidate = FinanceCategorySuggestion(
      category: tx.category,
      confidence: confidence,
      source: FinanceCategorySuggestionSource.history,
    );

    if (bestHistorySuggestion == null ||
        candidate.confidence > bestHistorySuggestion.confidence) {
      bestHistorySuggestion = candidate;
    }
  }

  if (bestHistorySuggestion != null &&
      bestHistorySuggestion.confidence >= 0.62) {
    return bestHistorySuggestion;
  }

  return _suggestByAmountAndType(type, amount, recurringPatterns);
}

String? suggestFinanceCategory({
  required String note,
  required FinanceTransactionType type,
  required double amount,
  required List<FinanceTransaction> history,
  required List<RecurringTransactionPattern> recurringPatterns,
}) {
  return suggestFinanceCategoryWithConfidence(
    note: note,
    type: type,
    amount: amount,
    history: history,
    recurringPatterns: recurringPatterns,
  )?.category;
}

FinanceCategorySuggestion? _suggestByAmountAndType(
  FinanceTransactionType type,
  double amount,
  List<RecurringTransactionPattern> recurringPatterns,
) {
  if (amount <= 0) {
    return null;
  }

  RecurringTransactionPattern? bestPattern;
  double? bestDiff;

  for (final pattern in recurringPatterns) {
    if (pattern.type != type) {
      continue;
    }

    final amountDiff = (pattern.amount - amount).abs();
    if (amountDiff > max(1.0, amount * 0.08)) {
      continue;
    }

    if (bestDiff == null || amountDiff < bestDiff) {
      bestPattern = pattern;
      bestDiff = amountDiff;
    }
  }

  if (bestPattern == null || bestDiff == null) {
    return null;
  }

  final amountBaseline = max(1.0, amount.abs());
  final closeness = (1 - (bestDiff / amountBaseline)).clamp(0.2, 1.0);
  final confidence =
      ((bestPattern.confidence * 0.7) + (closeness * 0.3)).clamp(0.5, 0.93);

  return FinanceCategorySuggestion(
    category: bestPattern.category,
    confidence: confidence.toDouble(),
    source: FinanceCategorySuggestionSource.recurring,
  );
}
