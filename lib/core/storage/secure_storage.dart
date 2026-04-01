import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

/// Secure storage for sensitive data like tokens
class SecureStorage {
  SecureStorage._();
  
  static final SecureStorage _instance = SecureStorage._();
  static SecureStorage get instance => _instance;
  
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  /// Write data to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.debug('Written to secure storage: $key', 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to write to secure storage', e, null, 'SecureStorage');
    }
  }
  
  /// Read data from secure storage
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('Failed to read from secure storage', e, null, 'SecureStorage');
      return null;
    }
  }
  
  /// Delete data from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.debug('Deleted from secure storage: $key', 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to delete from secure storage', e, null, 'SecureStorage');
    }
  }
  
  /// Clear all data from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.debug('Cleared all secure storage', 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to clear secure storage', e, null, 'SecureStorage');
    }
  }
  
  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      AppLogger.error('Failed to check key in secure storage', e, null, 'SecureStorage');
      return false;
    }
  }
}

