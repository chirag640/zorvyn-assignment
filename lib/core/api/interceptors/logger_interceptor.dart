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
      options.headers.forEach((k, v) => AppLogger.debug('│   $k: $v', _tag));
      AppLogger.debug('├$_line', _tag);
    }

    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug('│ 🔍 Query:', _tag);
      options.queryParameters
          .forEach((k, v) => AppLogger.debug('│   $k: $v', _tag));
      AppLogger.debug('├$_line', _tag);
    }

    if (options.data != null) {
      AppLogger.debug('│ 📤 Body:', _tag);
      _prettyJson(options.data)
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
      _prettyJson(response.data)
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
      err,
      err.stackTrace,
      _tag,
    );

    if (err.message != null) {
      AppLogger.warning('│ 💬 ${err.message}', _tag);
    }

    if (err.response != null) {
      AppLogger.warning(
          '│ 📊 Status: ${err.response!.statusCode}', _tag);
      if (err.response!.data != null) {
        AppLogger.debug('│ 📥 Error Body:', _tag);
        _prettyJson(err.response!.data)
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
}

