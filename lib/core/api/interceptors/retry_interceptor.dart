import 'dart:math' as math;
import 'package:dio/dio.dart';

import '../../utils/logger.dart';

/// Enhanced retry interceptor with exponential backoff and jitter
/// Implements industry-standard retry logic to prevent retry storms
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
  });

  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  
  // Track retries per request to avoid global state issues
  final Map<RequestOptions, int> _retryMap = {};
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final retryCount = _retryMap[requestOptions] ?? 0;
    
    if (_shouldRetry(err) && retryCount < maxRetries) {
      _retryMap[requestOptions] = retryCount + 1;
      
      AppLogger.warning(
        'Retrying request: ${requestOptions.path} (attempt ${retryCount + 1}/$maxRetries)',
        'RetryInterceptor',
      );
      
      try {
        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(retryCount);
        await Future.delayed(delay);
        
        // Attempt the request again
        final response = await Dio().fetch(requestOptions);
        
        // Success - clean up tracking and resolve
        _retryMap.remove(requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If this was the last retry, clean up and pass the error
        if (retryCount + 1 >= maxRetries) {
          _retryMap.remove(requestOptions);
        }
        return handler.next(err);
      }
    }
    
    // No retry needed or max retries exceeded
    _retryMap.remove(requestOptions);
    return handler.next(err);
  }
  
  /// Calculate delay using exponential backoff with jitter
  /// Formula: min(maxDelay, baseDelay * (2 ^ retryCount)) + randomJitter
  Duration _calculateDelay(int retryCount) {
    final exponentialDelay = baseDelay.inMilliseconds * math.pow(2, retryCount);
    final cappedDelay = math.min(exponentialDelay.toDouble(), maxDelay.inMilliseconds.toDouble());
    
    // Add jitter: random value between 0 and 20% of the delay
    final jitter = math.Random().nextDouble() * 0.2 * cappedDelay;
    
    return Duration(milliseconds: (cappedDelay + jitter).toInt());
  }
  
  /// Determine if the error should trigger a retry
  bool _shouldRetry(DioException err) {
    // Retry on timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    
    // Retry on connection errors
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      return true;
    }
    
    // Retry on 5xx server errors (transient issues)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }
    
    // Retry on specific 429 (rate limit) with proper backoff
    if (statusCode == 429) {
      return true;
    }
    
    // Don't retry 4xx client errors (except 429)
    return false;
  }
  
  /// Clean up tracking for a specific request
  void clearRetryTracking(RequestOptions options) {
    _retryMap.remove(options);
  }
  
  /// Clear all retry tracking (useful for testing)
  void clearAllRetryTracking() {
    _retryMap.clear();
  }
}

