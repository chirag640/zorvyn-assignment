import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import 'hive_database.dart';

/// Sync operation types
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Pending sync operation
class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });
  
  final String id;
  final SyncOperationType type;
  final String endpoint;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'endpoint': endpoint,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };
  
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      endpoint: json['endpoint'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
  
  SyncOperation copyWith({int? retryCount}) {
    return SyncOperation(
      id: id,
      type: type,
      endpoint: endpoint,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Manages offline-to-online data synchronization
class SyncManager {
  SyncManager({
    this.maxRetries = 3,
    Dio? dio,
  }) : _dio = dio ?? Dio();
  
  final int maxRetries;
  final Dio _dio;
  
  Box<Map>? _syncBox;
  final Queue<SyncOperation> _syncQueue = Queue<SyncOperation>();
  bool _isSyncing = false;
  
  /// Initialize sync manager
  Future<void> init() async {
    _syncBox = await HiveDatabase.instance.openBox<Map>('sync_queue');
    await _loadPendingSyncs();
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        sync();
      }
    });
    
    AppLogger.info('Sync manager initialized', 'SyncManager');
  }
  
  /// Add operation to sync queue
  Future<void> addToQueue(SyncOperation operation) async {
    _ensureInitialized();
    
    await _syncBox!.put(operation.id, operation.toJson());
    _syncQueue.add(operation);
    
    AppLogger.debug(
      'Added to sync queue: ${operation.type.name} ${operation.endpoint}',
      'SyncManager',
    );
    
    // Try to sync immediately if online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      await sync();
    }
  }
  
  /// Process sync queue
  Future<void> sync() async {
    _ensureInitialized();
    
    if (_isSyncing) {
      AppLogger.debug('Sync already in progress', 'SyncManager');
      return;
    }
    
    if (_syncQueue.isEmpty) {
      AppLogger.debug('Sync queue is empty', 'SyncManager');
      return;
    }
    
    _isSyncing = true;
    AppLogger.info('Starting sync (${_syncQueue.length} operations)', 'SyncManager');
    
    final failedOperations = <SyncOperation>[];
    
    while (_syncQueue.isNotEmpty) {
      final operation = _syncQueue.removeFirst();
      try {
        final response = await _executeApiCall(operation);
        
        // Remove from persistent storage on success
        await _syncBox!.delete(operation.id);
        
        AppLogger.success(
          'Synced: ${operation.type.name} ${operation.endpoint} (status: ${response.statusCode})',
          'SyncManager',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Sync failed: ${operation.endpoint}',
          e,
          stackTrace,
          'SyncManager',
        );
        
        // Retry logic
        if (operation.retryCount < maxRetries) {
          final retried = operation.copyWith(retryCount: operation.retryCount + 1);
          failedOperations.add(retried);
          await _syncBox!.put(retried.id, retried.toJson());
        } else {
          AppLogger.error(
            'Max retries reached for: ${operation.endpoint}',
            e,
            stackTrace,
            'SyncManager',
          );
          // Could move to dead letter queue here
        }
      }
    }
    
    // Re-add failed operations
    _syncQueue.addAll(failedOperations);
    
    _isSyncing = false;
    AppLogger.info('Sync completed', 'SyncManager');
  }
  
  /// Execute API call based on operation type
  Future<Response> _executeApiCall(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.create:
        return await _dio.post(
          operation.endpoint,
          data: operation.data,
        );
        
      case SyncOperationType.update:
        return await _dio.put(
          operation.endpoint,
          data: operation.data,
        );
        
      case SyncOperationType.delete:
        return await _dio.delete(
          operation.endpoint,
          data: operation.data,
        );
    }
  }
  
  /// Get pending sync count
  int get pendingCount => _syncQueue.length;
  
  /// Check if there are pending syncs
  bool get hasPendingSyncs => _syncQueue.isNotEmpty;
  
  /// Clear all pending syncs
  Future<void> clearQueue() async {
    _ensureInitialized();
    
    await _syncBox!.clear();
    _syncQueue.clear();
    AppLogger.warning('Sync queue cleared', 'SyncManager');
  }
  
  void _ensureInitialized() {
    if (_syncBox == null || !_syncBox!.isOpen) {
      throw StateError('SyncManager not initialized. Call init() first.');
    }
  }
  
  Future<void> _loadPendingSyncs() async {
    for (final key in _syncBox!.keys) {
      final json = _syncBox!.get(key) as Map<String, dynamic>?;
      if (json == null) continue;
      
      try {
        final operation = SyncOperation.fromJson(json);
        _syncQueue.add(operation);
      } catch (e) {
        AppLogger.error('Failed to load sync operation', e, null, 'SyncManager');
      }
    }
    
    AppLogger.info(
      'Loaded ${_syncQueue.length} pending syncs',
      'SyncManager',
    );
  }
}

