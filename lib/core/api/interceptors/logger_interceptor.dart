import 'dart:convert';

import 'package:dio/dio.dart';

import '../../utils/logger.dart';

/// Pretty-printing Dio interceptor that routes all output through [AppLogger].
///
/// Logs:
/// - **REQUEST** — method, URL, headers, query params, JSON body (indented)
/// - **RESPONSE** — status code, URL, JSON body (indented)
/// - **ERROR** — type, message, status code, error body
///
/// All output is suppressed in release mode because [AppLogger] wraps
/// everything in `kDebugMode` guards.
class LoggerInterceptor extends Interceptor {
  static const _tag = 'HTTP';
  static const _line =
      '─────────────────────────────────────────────────────────────────';

  static const Set<String> _sensitiveExactKeys = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'apikey',
    'access_token',
    'refresh_token',
    'password',
    'client_secret',
    'supabase_anon_key',
    'supabase_publishable_key',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('┌$_line', _tag);
    AppLogger.debug(
      '│ ► ${options.method.toUpperCase()} '
      '${options.baseUrl}${options.path}',
      _tag,
    );
    AppLogger.debug('├$_line', _tag);

    if (options.headers.isNotEmpty) {
      AppLogger.debug('│ 📋 Headers:', _tag);
      _redactMap(options.headers)
          .forEach((k, v) => AppLogger.debug('│   $k: $v', _tag));
      AppLogger.debug('├$_line', _tag);
    }

    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug('│ 🔍 Query:', _tag);
      _redactMap(options.queryParameters)
          .forEach((k, v) => AppLogger.debug('│   $k: $v', _tag));
      AppLogger.debug('├$_line', _tag);
    }

    if (options.data != null) {
      AppLogger.debug('│ 📤 Body:', _tag);
      _prettyJson(_sanitizeData(options.data))
          .forEach((line) => AppLogger.debug('│   $line', _tag));
      AppLogger.debug('├$_line', _tag);
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.success(
      '│ ✅ ${response.statusCode} '
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
      _tag,
    );

    if (response.data != null) {
      AppLogger.debug('├$_line', _tag);
      AppLogger.debug('│ 📥 Response Body:', _tag);
      _prettyJson(_sanitizeData(response.data))
          .forEach((line) => AppLogger.debug('│   $line', _tag));
    }

    AppLogger.debug('└$_line', _tag);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '│ ❌ ${err.type.name.toUpperCase()} '
      '${err.requestOptions.baseUrl}${err.requestOptions.path}',
      null,
      err.stackTrace,
      _tag,
    );

    if (err.message != null) {
      AppLogger.warning('│ 💬 ${err.message}', _tag);
    }

    if (err.response != null) {
      AppLogger.warning('│ 📊 Status: ${err.response!.statusCode}', _tag);
      if (err.response!.data != null) {
        AppLogger.debug('│ 📥 Error Body:', _tag);
        _prettyJson(_sanitizeData(err.response!.data))
            .forEach((line) => AppLogger.debug('│   $line', _tag));
      }
    }

    AppLogger.debug('└$_line', _tag);
    super.onError(err, handler);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<String> _prettyJson(dynamic data) {
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(data).split('\n');
    } catch (_) {
      return [data.toString()];
    }
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().trim();
    if (_sensitiveExactKeys.contains(normalized)) {
      return true;
    }

    return normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('secret') ||
        normalized.contains('auth');
  }

  Map<String, dynamic> _redactMap(Map<dynamic, dynamic> source) {
    final output = <String, dynamic>{};
    source.forEach((key, value) {
      final keyText = key.toString();
      if (_isSensitiveKey(keyText)) {
        output[keyText] = '<redacted>';
      } else {
        output[keyText] = _sanitizeData(value);
      }
    });
    return output;
  }

  dynamic _sanitizeData(dynamic value) {
    if (value is Map) {
      return _redactMap(value);
    }

    if (value is List) {
      return value.map(_sanitizeData).toList(growable: false);
    }

    return value;
  }
}
