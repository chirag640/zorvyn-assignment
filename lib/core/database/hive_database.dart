import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';

/// Hive database manager for offline-first architecture
class HiveDatabase {
  HiveDatabase._();
  
  static final HiveDatabase _instance = HiveDatabase._();
  static HiveDatabase get instance => _instance;
  
  bool _initialized = false;
  
  /// Initialize Hive database
  /// Call this before runApp() in main.dart
  Future<void> init() async {
    if (_initialized) {
      AppLogger.warning('Hive already initialized', 'HiveDatabase');
      return;
    }
    
    try {
      // Initialize Hive for Flutter
      await Hive.initFlutter();
      
      // For production: use app documents directory
      // final appDir = await getApplicationDocumentsDirectory();
      // Hive.init(appDir.path);
      
      // Register adapters here
      // Example: Hive.registerAdapter(UserModelAdapter());
      
      _initialized = true;
      AppLogger.success('Hive database initialized', 'HiveDatabase');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Hive', e, stackTrace, 'HiveDatabase');
      rethrow;
    }
  }
  
  /// Open a box (cache)
  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_initialized) {
      throw StateError('Hive not initialized. Call HiveDatabase.instance.init() first.');
    }
    
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }
      
      final box = await Hive.openBox<T>(boxName);
      AppLogger.debug('Opened box: $boxName', 'HiveDatabase');
      return box;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to open box: $boxName', e, stackTrace, 'HiveDatabase');
      rethrow;
    }
  }
  
  /// Open a lazy box (loads data on-demand)
  Future<LazyBox<T>> openLazyBox<T>(String boxName) async {
    if (!_initialized) {
      throw StateError('Hive not initialized. Call HiveDatabase.instance.init() first.');
    }
    
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.lazyBox<T>(boxName);
      }
      
      final box = await Hive.openLazyBox<T>(boxName);
      AppLogger.debug('Opened lazy box: $boxName', 'HiveDatabase');
      return box;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to open lazy box: $boxName', e, stackTrace, 'HiveDatabase');
      rethrow;
    }
  }
  
  /// Close a specific box
  Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
        AppLogger.debug('Closed box: $boxName', 'HiveDatabase');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to close box: $boxName', e, stackTrace, 'HiveDatabase');
    }
  }
  
  /// Close all boxes
  Future<void> closeAll() async {
    try {
      await Hive.close();
      _initialized = false;
      AppLogger.info('Closed all Hive boxes', 'HiveDatabase');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to close Hive boxes', e, stackTrace, 'HiveDatabase');
    }
  }
  
  /// Delete a box (clears all data)
  Future<void> deleteBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      AppLogger.info('Deleted box: $boxName', 'HiveDatabase');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete box: $boxName', e, stackTrace, 'HiveDatabase');
    }
  }
  
  /// Check if a box exists
  bool boxExists(String boxName) {
    return Hive.isBoxOpen(boxName);
  }
  
  /// Get box size in bytes
  int getBoxSize(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      return 0;
    }
    
    try {
      final box = Hive.box(boxName);
      // Estimate: each entry ~= 100 bytes (rough estimate)
      return box.length * 100;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear all data from all boxes
  Future<void> clearAllData() async {
    try {
      await Hive.deleteFromDisk();
      _initialized = false;
      AppLogger.warning('Cleared all Hive data', 'HiveDatabase');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear Hive data', e, stackTrace, 'HiveDatabase');
    }
  }
}

