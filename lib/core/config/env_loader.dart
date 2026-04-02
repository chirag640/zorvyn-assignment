import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, stage, prod }

class EnvLoader {
  static const String _defaultEnvironment = 'dev';
  static const String _defaultSupabaseUrl = '';
  static const String _defaultSupabaseAnonKey = '';
  static const String _defaultSupabasePublishableKey = '';

  static const String _defineSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _defineSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _defineSupabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  static AppEnvironment currentEnvironment = AppEnvironment.dev;
  static bool _loadedFromBundle = false;

  static bool get loadedFromBundle => _loadedFromBundle;

  static Future<void> load({String fileName = '.env'}) async {
    var loadedFromBundle = false;

    try {
      await dotenv.load(fileName: fileName);
      loadedFromBundle = true;
    } catch (_) {
      await dotenv.load(fileName: fileName, isOptional: true);
    }

    _loadedFromBundle = loadedFromBundle;

    final envName =
        (dotenv.maybeGet('APP_ENV', fallback: _defaultEnvironment) ??
                _defaultEnvironment)
            .trim()
            .toLowerCase();

    currentEnvironment = AppEnvironment.values.firstWhere(
      (element) => element.name == envName,
      orElse: () => AppEnvironment.dev,
    );
  }

  static String get supabaseUrl => _readEnv(
        key: 'SUPABASE_URL',
        defaultValue: _defaultSupabaseUrl,
        defineFallback: _defineSupabaseUrl,
      );

  static String get supabasePublishableKey => _readEnv(
        key: 'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: _defaultSupabasePublishableKey,
        defineFallback: _defineSupabasePublishableKey,
      );

  static String get supabaseAnonKey {
    final anon = _readEnv(
      key: 'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseAnonKey,
      defineFallback: _defineSupabaseAnonKey,
    );

    if (anon.trim().isNotEmpty) {
      return anon;
    }

    return supabasePublishableKey;
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String _readEnv({
    required String key,
    required String defaultValue,
    String defineFallback = '',
  }) {
    final fromDotenv = _normalizeEnvValue(dotenv.maybeGet(key));
    if (fromDotenv.isNotEmpty) {
      return fromDotenv;
    }

    final fromDefine = _normalizeEnvValue(defineFallback);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    return _normalizeEnvValue(defaultValue);
  }

  static String _normalizeEnvValue(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }

    if ((raw.startsWith('"') && raw.endsWith('"')) ||
        (raw.startsWith("'") && raw.endsWith("'"))) {
      return raw.substring(1, raw.length - 1).trim();
    }

    return raw;
  }
}
