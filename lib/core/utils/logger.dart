import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Professional logging utility with different log levels
class AppLogger {
  AppLogger._();

  static const String _prefix = '🚀 [Frontend]';

  /// Log debug messages (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix 🐛 $tagText $message');
    }
  }

  /// Log info messages
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ℹ️ $tagText $message');
    }
  }

  /// Log warning messages
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ⚠️ $tagText $message');
    }
  }

  /// Log error messages
  static void error(String message,
      [dynamic error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ❌ $tagText $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Log success messages
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final tagText = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ✅ $tagText $message');
    }
  }

  /// Log structured lifecycle events for auth/sync and operational flows.
  static void lifecycle(
    String event, {
    Map<String, Object?> data = const <String, Object?>{},
    String? tag,
    String level = 'info',
  }) {
    if (!kDebugMode) {
      return;
    }

    final payload = <String, Object?>{
      'event': event,
      'at': DateTime.now().toIso8601String(),
      if (data.isNotEmpty) 'data': _normalizeValue(data),
    };

    final message = jsonEncode(payload);
    switch (level.toLowerCase()) {
      case 'debug':
        debug(message, tag);
        return;
      case 'warning':
        warning(message, tag);
        return;
      case 'error':
        error(message, null, null, tag);
        return;
      case 'success':
        success(message, tag);
        return;
      default:
        info(message, tag);
        return;
    }
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _normalizeValue(item)),
      );
    }

    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }

    return value.toString();
  }
}
