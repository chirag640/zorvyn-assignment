import 'dart:async';
import 'package:dio/dio.dart';

import '../../storage/local_storage.dart';
import '../../constants/app_constants.dart';
import '../../utils/logger.dart';

/// Authentication interceptor with token refresh capability.
/// 
/// Automatically attaches JWT tokens to requests and handles
/// 401 responses by refreshing the token and retrying.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  
  final LocalStorage _storage;
  // Queue to hold requests during token refresh
  final List<_RequestQueueItem> _requestQueue = [];
  bool _isRefreshing = false;
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for refresh token endpoint
    if (options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }
    
    final token = _storage.getString(AppConstants.keyAccessToken);
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      AppLogger.debug('Added auth token to request: ${options.path}', 'AuthInterceptor');
    }
    
    handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      AppLogger.warning('Unauthorized error - attempting token refresh', 'AuthInterceptor');
      
      // If already refreshing, queue this request
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _requestQueue.add(_RequestQueueItem(err.requestOptions, completer));
        
        try {
          final response = await completer.future;
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
      
      _isRefreshing = true;
      
      try {
        final newToken = await _refreshToken();
        
        if (newToken != null) {
          // Retry with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          
          final response = await Dio().fetch(options);
          _processQueuedRequests(newToken);
          
          return handler.resolve(response);
        } else {
          _rejectQueuedRequests(err);
          return handler.next(err);
        }
      } catch (e) {
        AppLogger.error('Token refresh failed', e, null, 'AuthInterceptor');
        _rejectQueuedRequests(err);
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }
    
    handler.next(err);
  }
  
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = _storage.getString(AppConstants.keyRefreshToken);
      
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.warning('No refresh token available', 'AuthInterceptor');
        return null;
      }
      
      final dio = Dio();
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final newAccessToken = data?['access_token']?.toString();
        final newRefreshToken = data?['refresh_token']?.toString();
        
        if (newAccessToken != null) {
          await _storage.setString(AppConstants.keyAccessToken, newAccessToken);
          
          if (newRefreshToken != null) {
            await _storage.setString(AppConstants.keyRefreshToken, newRefreshToken);
          }
          
          AppLogger.info('Token refreshed successfully', 'AuthInterceptor');
          return newAccessToken;
        }
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Token refresh error', e, null, 'AuthInterceptor');
      
      await _storage.remove(AppConstants.keyAccessToken);
      await _storage.remove(AppConstants.keyRefreshToken);
      
      return null;
    }
  }
  
  void _processQueuedRequests(String newToken) async {
    for (final item in _requestQueue) {
      try {
        item.options.headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(item.options);
        item.completer.complete(response);
      } catch (e) {
        item.completer.completeError(e);
      }
    }
    _requestQueue.clear();
  }
  
  void _rejectQueuedRequests(DioException error) {
    for (final item in _requestQueue) {
      item.completer.completeError(error);
    }
    _requestQueue.clear();
  }
}

class _RequestQueueItem {
  _RequestQueueItem(this.options, this.completer);
  
  final RequestOptions options;
  final Completer<Response> completer;
}

