import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../config/env_loader.dart';
import '../storage/local_storage.dart';
import '../database/cache_manager.dart';
import '../supabase/supabase_service.dart';

/// Global provider for LocalStorage
/// Must be overridden with an initialized instance in main()
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('localStorageProvider must be overridden in main()');
});

/// Cache manager provider for home items
final homeCacheManagerProvider = Provider<CacheManager<List>>((ref) {
  return CacheManager<List>(boxName: 'home_cache');
});

class SupabaseBootstrapState {
  const SupabaseBootstrapState({
    required this.isChecking,
    required this.isReady,
    this.error,
  });

  const SupabaseBootstrapState.initial()
      : this(
          isChecking: true,
          isReady: false,
        );

  final bool isChecking;
  final bool isReady;
  final String? error;

  SupabaseBootstrapState copyWith({
    bool? isChecking,
    bool? isReady,
    String? error,
  }) {
    return SupabaseBootstrapState(
      isChecking: isChecking ?? this.isChecking,
      isReady: isReady ?? this.isReady,
      error: error,
    );
  }
}

class SupabaseBootstrapNotifier extends StateNotifier<SupabaseBootstrapState> {
  SupabaseBootstrapNotifier() : super(const SupabaseBootstrapState.initial()) {
    bootstrap();
  }

  Future<void> bootstrap() async {
    state = const SupabaseBootstrapState(
      isChecking: true,
      isReady: false,
    );

    await EnvLoader.load();
    final initialized = await SupabaseService.initialize();

    if (initialized) {
      state = const SupabaseBootstrapState(
        isChecking: false,
        isReady: true,
      );
      return;
    }

    state = SupabaseBootstrapState(
      isChecking: false,
      isReady: false,
      error: SupabaseService.initializationError ??
          'Supabase initialization failed. Verify env values and retry.',
    );
  }
}

final supabaseBootstrapProvider =
    StateNotifierProvider<SupabaseBootstrapNotifier, SupabaseBootstrapState>(
        (ref) {
  return SupabaseBootstrapNotifier();
});

/// Whether Supabase credentials are available in environment config.
final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  return SupabaseService.isConfigured;
});

/// Nullable Supabase client. Null means bootstrap is not configured/initialized yet.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.client;
});
