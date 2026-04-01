import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../api/api_client.dart';
import '../storage/local_storage.dart';
import '../database/cache_manager.dart';

/// Global provider for app configuration
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.load();
});

/// Global provider for API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(config);
});

/// Global provider for LocalStorage
/// Must be overridden with an initialized instance in main()
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main()');
});

/// Cache manager provider for home items
final homeCacheManagerProvider = Provider<CacheManager<List>>((ref) {
  return CacheManager<List>(boxName: 'home_cache');
});

