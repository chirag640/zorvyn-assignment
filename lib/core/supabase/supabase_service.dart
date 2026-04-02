import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_loader.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static String? _initializationError;

  static bool get isInitialized => _initialized;
  static bool get isConfigured => EnvLoader.isSupabaseConfigured;
  static String? get initializationError => _initializationError;

  static SupabaseClient? get client {
    if (!_initialized) {
      return null;
    }
    return Supabase.instance.client;
  }

  static Future<bool> initialize() async {
    if (_initialized) {
      debugPrint('Supabase already initialized.');
      _initializationError = null;
      return true;
    }

    if (!isConfigured) {
      _initialized = false;
      final hasUrl = EnvLoader.supabaseUrl.trim().isNotEmpty;
      final hasAnonKey = EnvLoader.supabaseAnonKey.trim().isNotEmpty;
      final envLoaded = EnvLoader.loadedFromBundle;

      _initializationError =
          'Supabase is not configured. SUPABASE_URL set: $hasUrl, '
          'SUPABASE_ANON_KEY/PUBLISHABLE set: $hasAnonKey, '
          '.env loaded from bundle: $envLoaded.\n\n'
          'Required: SUPABASE_URL plus SUPABASE_ANON_KEY (or '
          'SUPABASE_PUBLISHABLE_KEY) in frontend/.env.\n'
          'After env or pubspec asset changes, fully restart the app.';

      debugPrint(
        'Supabase not configured. SUPABASE_URL set: $hasUrl, '
        'SUPABASE_ANON_KEY set: $hasAnonKey.',
      );
      debugPrint(
        'If you use flutter_dotenv, ensure .env is listed in flutter assets in pubspec.yaml.',
      );
      return false;
    }

    try {
      await Supabase.initialize(
        url: EnvLoader.supabaseUrl,
        anonKey: EnvLoader.supabaseAnonKey,
      );
      _initialized = true;
      _initializationError = null;
      debugPrint('Supabase initialized successfully.');
      return true;
    } catch (error, stackTrace) {
      _initialized = false;
      _initializationError = 'Supabase initialization failed: $error\n\n'
          'Verify SUPABASE_URL and SUPABASE_ANON_KEY (or '
          'SUPABASE_PUBLISHABLE_KEY) in frontend/.env, then fully restart '
          'the app.';
      debugPrint('Supabase initialization failed: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
