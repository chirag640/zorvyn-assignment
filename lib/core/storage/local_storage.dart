import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced local storage with JSON serialization support
class LocalStorage {
  LocalStorage._();
  
  static LocalStorage? _instance;
  static SharedPreferences? _prefs;
  
  static Future<LocalStorage> getInstance() async {
    _instance ??= LocalStorage._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }
  
  // ========== String operations ==========
  
  Future<bool> setString(String key, String value) async {
    return await _prefs!.setString(key, value);
  }
  
  String? getString(String key) {
    return _prefs!.getString(key);
  }
  
  // ========== JSON operations ==========
  
  /// Save any JSON-serializable object
  Future<bool> setJson<T>(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = json.encode(value);
      return await setString(key, jsonString);
    } catch (e) {
      return false;
    }
  }
  
  /// Read and parse JSON object
  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Save list of JSON objects
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = json.encode(value);
      return await setString(key, jsonString);
    } catch (e) {
      return false;
    }
  }
  
  /// Read list of JSON objects
  List<Map<String, dynamic>>? getJsonList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      final decoded = json.decode(jsonString);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }
  
  // ========== Int operations ==========
  
  Future<bool> setInt(String key, int value) async {
    return await _prefs!.setInt(key, value);
  }
  
  int? getInt(String key) {
    return _prefs!.getInt(key);
  }
  
  // ========== Bool operations ==========
  
  Future<bool> setBool(String key, bool value) async {
    return await _prefs!.setBool(key, value);
  }
  
  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }
  
  // ========== Double operations ==========
  
  Future<bool> setDouble(String key, double value) async {
    return await _prefs!.setDouble(key, value);
  }
  
  double? getDouble(String key) {
    return _prefs!.getDouble(key);
  }
  
  // ========== List operations ==========
  
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs!.setStringList(key, value);
  }
  
  List<String>? getStringList(String key) {
    return _prefs!.getStringList(key);
  }
  
  // ========== Utility operations ==========
  
  Future<bool> remove(String key) async {
    return await _prefs!.remove(key);
  }
  
  Future<bool> clear() async {
    return await _prefs!.clear();
  }
  
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }
  
  Set<String> getKeys() {
    return _prefs!.getKeys();
  }
  
  /// Get approximate storage size in bytes (rough estimate)
  int getApproximateSize() {
    int totalSize = 0;
    for (final key in getKeys()) {
      final value = _prefs!.get(key);
      if (value is String) {
        totalSize += value.length * 2; // UTF-16 encoding
      } else if (value is int) {
        totalSize += 8;
      } else if (value is double) {
        totalSize += 8;
      } else if (value is bool) {
        totalSize += 1;
      } else if (value is List<String>) {
        for (final item in value) {
          totalSize += item.length * 2;
        }
      }
    }
    return totalSize;
  }
  
  /// Clean up old entries based on timestamp keys
  Future<void> cleanupOldEntries({
    required String prefix,
    required Duration maxAge,
  }) async {
    final now = DateTime.now();
    final keys = getKeys().where((k) => k.startsWith(prefix));
    
    for (final key in keys) {
      final timestamp = getInt('${key}_timestamp');
      if (timestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (now.difference(savedTime) > maxAge) {
          await remove(key);
          await remove('${key}_timestamp');
        }
      }
    }
  }
}

