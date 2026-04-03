import 'dart:async';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/logger.dart';
import '../datasources/finance_supabase_data_source.dart';
import '../utils/finance_id_generator.dart';
import 'finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl({
    required this.localStorage,
    required this.remoteDataSource,
    this.userScopeId,
  });

  final LocalStorage localStorage;
  final FinanceSupabaseDataSource? remoteDataSource;
  final String? userScopeId;

  static const String _transactionsKeyBase = 'finance_transactions_v1';
  static const String _settingsKeyBase = 'finance_goal_settings_v1';
  static const String _syncQueueKeyBase = 'finance_sync_queue_v1';

  String get _transactionsKey => _scopedKey(_transactionsKeyBase);
  String get _settingsKey => _scopedKey(_settingsKeyBase);
  String get _syncQueueKey => _scopedKey(_syncQueueKeyBase);

  static const String _operationUpsertTransaction = 'upsertTransaction';
  static const String _operationDeleteTransaction = 'deleteTransaction';
  static const String _operationUpsertGoalSettings = 'upsertGoalSettings';

  static const int _maxSyncAttempts = 3;
  static const int _retryBaseDelayMs = 300;
  static const int _maxQueuedOperationAttempts = 6;
  static const Duration _requestTimeout = Duration(seconds: 12);

  @override
  Future<FinanceLoadResult> load() async {
    final localTransactions = _readLocalTransactions();
    final localGoalSettings = _readLocalGoalSettings();
    final queuedCount = _readSyncQueue().length;

    AppLogger.lifecycle(
      'finance.load.start',
      tag: 'FinanceSyncLifecycle',
      data: {
        'localTransactions': localTransactions.length,
        'hasRemote': remoteDataSource != null,
        'queuedOps': queuedCount,
      },
      level: 'debug',
    );

    var mergedTransactions = localTransactions;
    var mergedGoalSettings = localGoalSettings;
    var syncResult = FinanceSyncResult(
      pendingOperations: queuedCount,
    );

    final remote = _resolveRemoteDataSource();
    if (remote != null) {
      syncResult = await syncPendingOperations();

      String? syncError = syncResult.errorMessage;
      var remoteTransactions = const <Map<String, dynamic>>[];
      FinanceGoalSettingsData? remoteGoalSettings;

      try {
        remoteTransactions = await remote.fetchTransactions();
      } catch (error, stackTrace) {
        AppLogger.lifecycle(
          'finance.sync.remote_pull_transactions_failure',
          tag: 'FinanceSyncLifecycle',
          data: {
            'errorType': error.runtimeType.toString(),
          },
          level: 'warning',
        );
        syncError ??= error.toString();
        AppLogger.warning(
          'Finance remote transaction pull failed: $error',
          'FinanceRepository',
        );
        AppLogger.error(
          'Finance remote transaction pull stack trace',
          error,
          stackTrace,
          'FinanceRepository',
        );
      }

      try {
        final goalMap = await remote.fetchGoalSettings();
        if (goalMap != null) {
          remoteGoalSettings = FinanceGoalSettingsData.fromJson(goalMap);
        }
      } catch (error, stackTrace) {
        AppLogger.lifecycle(
          'finance.sync.remote_pull_goals_failure',
          tag: 'FinanceSyncLifecycle',
          data: {
            'errorType': error.runtimeType.toString(),
          },
          level: 'warning',
        );
        syncError ??= error.toString();
        AppLogger.warning(
          'Finance remote goal pull failed: $error',
          'FinanceRepository',
        );
        AppLogger.error(
          'Finance remote goal pull stack trace',
          error,
          stackTrace,
          'FinanceRepository',
        );
      }

      mergedTransactions = _mergeTransactions(
        localTransactions,
        remoteTransactions,
      );

      if (remoteTransactions.isEmpty && localTransactions.isNotEmpty) {
        for (final transaction in localTransactions) {
          await _queueOperation(
            type: _operationUpsertTransaction,
            payload: transaction,
            transactionId: transaction['id'] as String? ?? '',
            syncAfterQueue: false,
          );
        }
      }

      if (remoteGoalSettings == null) {
        mergedGoalSettings = localGoalSettings;
        if (_hasMeaningfulLocalGoalSettings(localGoalSettings)) {
          await _queueOperation(
            type: _operationUpsertGoalSettings,
            payload: localGoalSettings.toJson(),
            syncAfterQueue: false,
          );
        }
      } else {
        mergedGoalSettings = _isGoalSettingsNewer(
                candidate: remoteGoalSettings, current: localGoalSettings)
            ? remoteGoalSettings
            : localGoalSettings;
      }

      final postMergeSyncResult = await syncPendingOperations();
      syncResult = FinanceSyncResult(
        pendingOperations: postMergeSyncResult.pendingOperations,
        errorMessage: postMergeSyncResult.errorMessage ?? syncError,
      );
    }

    await saveLocalSnapshot(
      transactions: mergedTransactions,
      goalSettings: mergedGoalSettings,
    );

    AppLogger.lifecycle(
      'finance.load.complete',
      tag: 'FinanceSyncLifecycle',
      data: {
        'mergedTransactions': mergedTransactions.length,
        'pendingOps': syncResult.pendingOperations,
        'hasError': syncResult.hasError,
      },
      level: syncResult.hasError ? 'warning' : 'info',
    );

    return FinanceLoadResult(
      transactions: mergedTransactions,
      goalSettings: mergedGoalSettings,
      syncResult: syncResult,
    );
  }

  @override
  Future<void> saveLocalSnapshot({
    required List<Map<String, dynamic>> transactions,
    required FinanceGoalSettingsData goalSettings,
  }) async {
    final normalizedTransactions =
        transactions.map(_normalizeTransaction).toList(growable: false)
          ..sort((a, b) {
            final left = _resolveTransactionTimestamp(a);
            final right = _resolveTransactionTimestamp(b);
            return right.compareTo(left);
          });

    final savedTransactions = await localStorage.setJsonList(
        _transactionsKey, normalizedTransactions);
    final savedSettings = await localStorage.setJson(
      _settingsKey,
      _normalizeGoalSettings(goalSettings).toJson(),
    );

    if (!savedTransactions || !savedSettings) {
      AppLogger.warning(
        'Finance local snapshot save was partially unsuccessful.',
        'FinanceRepository',
      );
    }
  }

  @override
  Future<FinanceSyncResult> queueUpsertTransaction(
    Map<String, dynamic> transaction,
  ) {
    final normalized = _normalizeTransaction(transaction);
    return _queueOperation(
      type: _operationUpsertTransaction,
      payload: normalized,
      transactionId: normalized['id'] as String? ?? '',
      syncAfterQueue: true,
    );
  }

  @override
  Future<FinanceSyncResult> queueDeleteTransaction(String transactionId) {
    return _queueOperation(
      type: _operationDeleteTransaction,
      payload: {'transactionId': transactionId},
      transactionId: transactionId,
      syncAfterQueue: true,
    );
  }

  @override
  Future<FinanceSyncResult> queueUpsertGoalSettings(
    FinanceGoalSettingsData goalSettings,
  ) {
    return _queueOperation(
      type: _operationUpsertGoalSettings,
      payload: _normalizeGoalSettings(goalSettings).toJson(),
      syncAfterQueue: true,
    );
  }

  @override
  Future<FinanceSyncResult> syncPendingOperations() async {
    final remote = _resolveRemoteDataSource();
    final queue = _readSyncQueue();

    if (queue.isEmpty) {
      AppLogger.lifecycle(
        'finance.sync.skip_empty_queue',
        tag: 'FinanceSyncLifecycle',
        level: 'debug',
      );
      return const FinanceSyncResult(pendingOperations: 0);
    }

    if (remote == null) {
      AppLogger.lifecycle(
        'finance.sync.skip_remote_unavailable',
        tag: 'FinanceSyncLifecycle',
        data: {
          'queuedOps': queue.length,
        },
        level: 'warning',
      );
      return FinanceSyncResult(
        pendingOperations: queue.length,
        errorMessage: 'Sync service unavailable. Retrying shortly.',
      );
    }

    AppLogger.lifecycle(
      'finance.sync.start',
      tag: 'FinanceSyncLifecycle',
      data: {
        'queuedOps': queue.length,
      },
      level: 'debug',
    );

    final remaining = <Map<String, dynamic>>[];
    String? syncError;
    var droppedOperations = 0;

    for (final operation in queue) {
      final attemptsSoFar = (operation['attempts'] as num?)?.toInt() ?? 0;
      if (attemptsSoFar >= _maxQueuedOperationAttempts) {
        droppedOperations += 1;
        continue;
      }

      try {
        await _executeOperation(operation);
      } catch (error, stackTrace) {
        final attempts = attemptsSoFar + 1;
        final type = (operation['type'] as String?) ?? 'unknown';
        final message = error.toString();
        syncError ??= message;

        if (attempts >= _maxQueuedOperationAttempts) {
          droppedOperations += 1;
          AppLogger.lifecycle(
            'finance.sync.operation_dropped',
            tag: 'FinanceSyncLifecycle',
            data: {
              'type': type,
              'attempts': attempts,
            },
            level: 'warning',
          );
        } else {
          remaining.add({
            ...operation,
            'attempts': attempts,
            'lastError': message,
            'lastAttemptAt': DateTime.now().toIso8601String(),
          });
        }

        AppLogger.lifecycle(
          'finance.sync.operation_failed',
          tag: 'FinanceSyncLifecycle',
          data: {
            'type': type,
            'attempts': attempts,
            'errorType': error.runtimeType.toString(),
          },
          level: 'warning',
        );
        AppLogger.warning(
          'Finance sync operation failed and was re-queued.',
          'FinanceRepository',
        );
        AppLogger.error(
          'Finance sync failure details',
          error,
          stackTrace,
          'FinanceRepository',
        );
      }
    }

    if (droppedOperations > 0) {
      final droppedMessage =
          '$droppedOperations failed sync operation${droppedOperations == 1 ? '' : 's'} were dropped after repeated failures.';
      syncError =
          syncError == null ? droppedMessage : '$syncError | $droppedMessage';
    }

    final savedQueue = await localStorage.setJsonList(_syncQueueKey, remaining);
    if (!savedQueue) {
      AppLogger.warning(
        'Failed to persist finance sync queue state.',
        'FinanceRepository',
      );
    }

    AppLogger.lifecycle(
      'finance.sync.complete',
      tag: 'FinanceSyncLifecycle',
      data: {
        'remainingOps': remaining.length,
        'hasError': syncError != null && syncError.trim().isNotEmpty,
      },
      level: syncError == null ? 'success' : 'warning',
    );

    return FinanceSyncResult(
      pendingOperations: remaining.length,
      errorMessage: syncError,
    );
  }

  Future<FinanceSyncResult> _queueOperation({
    required String type,
    required Map<String, dynamic> payload,
    String? transactionId,
    required bool syncAfterQueue,
  }) async {
    final queue = _readSyncQueue();

    if (type == _operationUpsertGoalSettings) {
      queue.removeWhere(
        (item) => (item['type'] as String?) == _operationUpsertGoalSettings,
      );
    }

    if (transactionId != null && transactionId.isNotEmpty) {
      queue.removeWhere(
        (item) => _isTransactionOperationForId(item, transactionId),
      );
    }

    queue.add({
      'type': type,
      'payload': payload,
      'queuedAt': DateTime.now().toIso8601String(),
      'attempts': 0,
    });

    final savedQueue = await localStorage.setJsonList(_syncQueueKey, queue);
    if (!savedQueue) {
      AppLogger.warning(
        'Failed to queue finance sync operation locally.',
        'FinanceRepository',
      );
    }

    AppLogger.lifecycle(
      'finance.sync.operation_queued',
      tag: 'FinanceSyncLifecycle',
      data: {
        'type': type,
        'queueSize': queue.length,
        'hasTransactionId': transactionId != null && transactionId.isNotEmpty,
      },
      level: 'debug',
    );

    if (!syncAfterQueue) {
      return FinanceSyncResult(pendingOperations: queue.length);
    }

    return syncPendingOperations();
  }

  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    final remote = _resolveRemoteDataSource();
    if (remote == null) {
      return;
    }

    final type = operation['type'] as String? ?? '';
    final payload = _asMap(operation['payload']);

    switch (type) {
      case _operationUpsertTransaction:
        final transaction = _normalizeTransaction(payload);
        await _runWithRetry(() => remote.upsertTransaction(transaction));
        return;
      case _operationDeleteTransaction:
        final transactionId =
            (payload['transactionId'] ?? payload['id'])?.toString().trim();
        if (transactionId == null || transactionId.isEmpty) {
          return;
        }
        await _runWithRetry(() => remote.deleteTransaction(transactionId));
        return;
      case _operationUpsertGoalSettings:
        final settings =
            _normalizeGoalSettings(FinanceGoalSettingsData.fromJson(payload));
        await _runWithRetry(
          () => remote.upsertGoalSettings(
            weeklySavingsTarget: settings.weeklySavingsTarget,
            weeklySpendLimit: settings.weeklySpendLimit,
            monthlySavingsGoal: settings.monthlySavingsGoal,
            dailySpendLimit: settings.dailySpendLimit,
            updatedAt: settings.updatedAt,
          ),
        );
        return;
      default:
        return;
    }
  }

  Future<void> _runWithRetry(Future<void> Function() operation) async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxSyncAttempts; attempt++) {
      try {
        await operation().timeout(
          _requestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Finance sync request timed out after '
              '${_requestTimeout.inSeconds}s.',
            );
          },
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (attempt >= _maxSyncAttempts) {
          break;
        }

        final delayMs = _retryBaseDelayMs * (1 << (attempt - 1));
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
  }

  List<Map<String, dynamic>> _readLocalTransactions() {
    final rows = localStorage.getJsonList(_transactionsKey) ?? const [];
    return rows.map(_normalizeTransaction).toList(growable: false)
      ..sort((a, b) {
        final left = _resolveTransactionTimestamp(a);
        final right = _resolveTransactionTimestamp(b);
        return right.compareTo(left);
      });
  }

  FinanceGoalSettingsData _readLocalGoalSettings() {
    final json = localStorage.getJson(_settingsKey);
    if (json == null) {
      return FinanceGoalSettingsData.defaults();
    }

    return _normalizeGoalSettings(FinanceGoalSettingsData.fromJson(json));
  }

  List<Map<String, dynamic>> _readSyncQueue() {
    final rows = localStorage.getJsonList(_syncQueueKey);
    if (rows == null || rows.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: true);
  }

  List<Map<String, dynamic>> _mergeTransactions(
    List<Map<String, dynamic>> localTransactions,
    List<Map<String, dynamic>> remoteTransactions,
  ) {
    final mergedById = <String, Map<String, dynamic>>{};

    void consume(Map<String, dynamic> row) {
      final normalized = _normalizeTransaction(row);
      final id = normalized['id'] as String? ?? '';
      if (id.isEmpty) {
        return;
      }

      final existing = mergedById[id];
      if (existing == null || _isTransactionNewer(normalized, existing)) {
        mergedById[id] = normalized;
      }
    }

    for (final transaction in localTransactions) {
      consume(transaction);
    }

    for (final transaction in remoteTransactions) {
      consume(transaction);
    }

    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) {
        final left = _resolveTransactionTimestamp(a);
        final right = _resolveTransactionTimestamp(b);
        return right.compareTo(left);
      });

    return merged;
  }

  bool _isTransactionNewer(
    Map<String, dynamic> candidate,
    Map<String, dynamic> current,
  ) {
    final candidateTime = _resolveTransactionTimestamp(candidate);
    final currentTime = _resolveTransactionTimestamp(current);
    return candidateTime.isAfter(currentTime);
  }

  DateTime _resolveTransactionTimestamp(Map<String, dynamic> transaction) {
    final updatedAt = transaction['updatedAt'] as String?;
    final occurredAt = transaction['date'] as String?;

    return _parseIsoDate(updatedAt) ??
        _parseIsoDate(occurredAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isGoalSettingsNewer({
    required FinanceGoalSettingsData candidate,
    required FinanceGoalSettingsData current,
  }) {
    final candidateTime = _parseIsoDate(candidate.updatedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final currentTime = _parseIsoDate(current.updatedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return candidateTime.isAfter(currentTime);
  }

  bool _hasMeaningfulLocalGoalSettings(FinanceGoalSettingsData settings) {
    final defaults = FinanceGoalSettingsData.defaults();
    return settings.updatedAt.trim().isNotEmpty ||
        settings.weeklySavingsTarget != defaults.weeklySavingsTarget ||
        settings.weeklySpendLimit != defaults.weeklySpendLimit ||
        settings.monthlySavingsGoal != defaults.monthlySavingsGoal ||
        settings.dailySpendLimit != defaults.dailySpendLimit;
  }

  Map<String, dynamic> _normalizeTransaction(Map<String, dynamic> json) {
    final nowIso = DateTime.now().toIso8601String();
    final normalizedDate =
        (_parseIsoDate(json['date'] as String?) ?? DateTime.now())
            .toIso8601String();
    final normalizedUpdatedAt = (_parseIsoDate(json['updatedAt'] as String?) ??
            _parseIsoDate(json['updated_at'] as String?) ??
            _parseIsoDate(normalizedDate) ??
            DateTime.now())
        .toIso8601String();

    return {
      'id': normalizeOrGenerateFinanceTransactionId(
        json['id']?.toString(),
      ),
      'amount': (json['amount'] as num?)?.toDouble() ?? 0,
      'type': (json['type'] as String? ?? 'expense').toLowerCase(),
      'category': (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'Other',
      'date': normalizedDate,
      'note': json['note'] as String?,
      'updatedAt': normalizedUpdatedAt.isEmpty ? nowIso : normalizedUpdatedAt,
    };
  }

  FinanceGoalSettingsData _normalizeGoalSettings(
    FinanceGoalSettingsData value,
  ) {
    final normalizedUpdatedAt =
        (_parseIsoDate(value.updatedAt) ?? DateTime.now()).toIso8601String();

    return FinanceGoalSettingsData(
      weeklySavingsTarget: value.weeklySavingsTarget,
      weeklySpendLimit: value.weeklySpendLimit,
      monthlySavingsGoal: value.monthlySavingsGoal,
      dailySpendLimit: value.dailySpendLimit,
      updatedAt: normalizedUpdatedAt,
    );
  }

  bool _isTransactionOperationForId(
    Map<String, dynamic> operation,
    String transactionId,
  ) {
    final type = operation['type'] as String?;
    if (type != _operationUpsertTransaction &&
        type != _operationDeleteTransaction) {
      return false;
    }

    final payload = _asMap(operation['payload']);
    final payloadId =
        (payload['transactionId'] ?? payload['id'])?.toString().trim() ?? '';
    return payloadId == transactionId;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }

    return <String, dynamic>{};
  }

  DateTime? _parseIsoDate(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  FinanceSupabaseDataSource? _resolveRemoteDataSource() {
    final configured = remoteDataSource;
    if (configured != null) {
      return configured;
    }

    final client = SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      return null;
    }

    return FinanceSupabaseDataSource(client);
  }

  String _scopedKey(String baseKey) {
    final scope = _normalizeScope(userScopeId);
    if (scope == null) {
      return baseKey;
    }

    return '${baseKey}_$scope';
  }

  String? _normalizeScope(String? rawScope) {
    final normalized = rawScope?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
