import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import 'hive_database.dart';

/// Cache strategies for managing data
enum CacheStrategy {
  /// Time-To-Live: data expires after specified duration
  ttl,
  
  /// Least Recently Used: removes least recently used items
  lru,
  
  /// Size-based: removes items when cache exceeds size limit
  sizeBased,
  
  /// No eviction: data persists until manually cleared
  noEviction,
}

/// Cache entry with metadata
class CacheEntry<T> {
  const CacheEntry({
    required this.data,
    required this.timestamp,
    this.ttl,
  });
  
  final T data;
  final DateTime timestamp;
  final Duration? ttl;
  
  /// Check if cache entry is expired
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(timestamp) > ttl!;
  }
  
  /// Time remaining until expiration
  Duration? get timeRemaining {
    if (ttl == null) return null;
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = ttl! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'ttl': ttl?.inSeconds,
  };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json, T data) {
    return CacheEntry(
      data: data,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl'] as int) : null,
    );
  }
}

/// Manages caching with various strategies
class CacheManager<T> {
  CacheManager({
    required this.boxName,
    this.strategy = CacheStrategy.ttl,
    this.defaultTTL = const Duration(hours: 24),
    this.maxSize = 1000,
  });
  
  final String boxName;
  final CacheStrategy strategy;
  final Duration defaultTTL;
  final int maxSize;
  
  Box<Map>? _box;
  
  /// Initialize cache
  Future<void> init() async {
    _box = await HiveDatabase.instance.openBox<Map>(boxName);
    AppLogger.debug('Cache initialized: $boxName', 'CacheManager');
    
    // Clean expired entries on init
    if (strategy == CacheStrategy.ttl) {
      await _cleanExpiredEntries();
    }
  }
  
  /// Store data in cache
  Future<void> put(
    String key,
    T data, {
    Duration? ttl,
  }) async {
    _ensureInitialized();
    
    final entry = CacheEntry<T>(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? (strategy == CacheStrategy.ttl ? defaultTTL : null),
    );
    
    await _box!.put(key, entry.toJson());
    AppLogger.debug('Cached: $key', 'CacheManager');
    
    // Apply cache strategy
    await _applyCacheStrategy();
  }
  
  /// Get data from cache
  T? get(String key) {
    _ensureInitialized();
    
    final json = _box!.get(key) as Map<String, dynamic>?;
    if (json == null) return null;
    
    final entry = CacheEntry.fromJson(json, json['data'] as T);
    
    // Check if expired
    if (entry.isExpired) {
      _box!.delete(key);
      AppLogger.debug('Cache expired: $key', 'CacheManager');
      return null;
    }
    
    // Update access time for LRU
    if (strategy == CacheStrategy.lru) {
      _updateAccessTime(key);
    }
    
    return entry.data;
  }
  
  /// Check if key exists and is not expired
  bool has(String key) {
    return get(key) != null;
  }
  
  /// Remove item from cache
  Future<void> remove(String key) async {
    _ensureInitialized();
    await _box!.delete(key);
    AppLogger.debug('Removed from cache: $key', 'CacheManager');
  }
  
  /// Clear all cache
  Future<void> clear() async {
    _ensureInitialized();
    await _box!.clear();
    AppLogger.info('Cache cleared: $boxName', 'CacheManager');
  }
  
  /// Get all cached keys
  List<String> get keys {
    _ensureInitialized();
    return _box!.keys.cast<String>().toList();
  }
  
  /// Get cache size
  int get size {
    _ensureInitialized();
    return _box!.length;
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStats() {
    _ensureInitialized();
    
    int expiredCount = 0;
    int validCount = 0;
    
    for (final key in _box!.keys) {
      final json = _box!.get(key) as Map<String, dynamic>?;
      if (json == null) continue;
      
      final entry = CacheEntry.fromJson(json, json['data']);
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }
    
    return {
      'boxName': boxName,
      'strategy': strategy.name,
      'totalEntries': _box!.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxSize': maxSize,
      'defaultTTL': defaultTTL.inSeconds,
    };
  }
  
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError('Cache not initialized. Call init() first.');
    }
  }
  
  Future<void> _cleanExpiredEntries() async {
    final keysToRemove = <String>[];
    
    for (final key in _box!.keys) {
      final json = _box!.get(key) as Map<String, dynamic>?;
      if (json == null) continue;
      
      final entry = CacheEntry.fromJson(json, json['data']);
      if (entry.isExpired) {
        keysToRemove.add(key.toString());
      }
    }
    
    for (final key in keysToRemove) {
      await _box!.delete(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      AppLogger.info(
        'Cleaned ${keysToRemove.length} expired entries',
        'CacheManager',
      );
    }
  }
  
  Future<void> _applyCacheStrategy() async {
    switch (strategy) {
      case CacheStrategy.ttl:
        await _cleanExpiredEntries();
        break;
      case CacheStrategy.lru:
        await _evictLRU();
        break;
      case CacheStrategy.sizeBased:
        await _evictBySize();
        break;
      case CacheStrategy.noEviction:
        // Do nothing
        break;
    }
  }
  
  Future<void> _evictLRU() async {
    if (_box!.length <= maxSize) return;
    
    final entries = <String, DateTime>{};
    
    for (final key in _box!.keys) {
      final json = _box!.get(key) as Map<String, dynamic>?;
      if (json == null) continue;
      
      final entry = CacheEntry.fromJson(json, json['data']);
      entries[key.toString()] = entry.timestamp;
    }
    
    // Sort by timestamp (oldest first)
    final sorted = entries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest entries
    final toRemove = sorted.take(_box!.length - maxSize);
    for (final entry in toRemove) {
      await _box!.delete(entry.key);
    }
    
    AppLogger.debug('Evicted ${toRemove.length} LRU entries', 'CacheManager');
  }
  
  Future<void> _evictBySize() async {
    if (_box!.length <= maxSize) return;
    
    // Remove random entries until we're under the limit
    final keysToRemove = _box!.keys.take(_box!.length - maxSize).toList();
    for (final key in keysToRemove) {
      await _box!.delete(key);
    }
    
    AppLogger.debug('Evicted ${keysToRemove.length} entries by size', 'CacheManager');
  }
  
  void _updateAccessTime(String key) {
    final json = _box!.get(key) as Map<String, dynamic>?;
    if (json == null) return;
    
    final entry = CacheEntry.fromJson(json, json['data']);
    final updated = CacheEntry<T>(
      data: entry.data,
      timestamp: DateTime.now(),
      ttl: entry.ttl,
    );
    
    _box!.put(key, updated.toJson());
  }
}

