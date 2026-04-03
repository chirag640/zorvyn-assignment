import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsSupabaseDataSource {
  SettingsSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const String _settingsTable = 'user_settings';

  String? get _userId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchSettings() async {
    final userId = _userId;
    if (userId == null) {
      return null;
    }

    final response = await _client
        .from(_settingsTable)
        .select(
          'theme_mode,notifications_enabled,biometrics_enabled,reduce_motion_enabled,inactivity_lock_enabled,inactivity_timeout_minutes,language,updated_at',
        )
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return {
      'themeMode': response['theme_mode'] ?? 'system',
      'notificationsEnabled': response['notifications_enabled'] ?? true,
      'biometricsEnabled': response['biometrics_enabled'] ?? false,
      'reduceMotionEnabled': response['reduce_motion_enabled'] ?? false,
      'inactivityLockEnabled': response['inactivity_lock_enabled'] ?? false,
      'inactivityTimeoutMinutes': response['inactivity_timeout_minutes'] ?? 5,
      'language': response['language'] ?? 'en',
      'updatedAt': (response['updated_at'] as String?) ?? '',
    };
  }

  Future<void> upsertSettings(Map<String, dynamic> settings) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    await _client.from(_settingsTable).upsert(
      {
        'user_id': userId,
        'theme_mode': settings['themeMode'] ?? 'system',
        'notifications_enabled': settings['notificationsEnabled'] ?? true,
        'biometrics_enabled': settings['biometricsEnabled'] ?? false,
        'reduce_motion_enabled': settings['reduceMotionEnabled'] ?? false,
        'inactivity_lock_enabled': settings['inactivityLockEnabled'] ?? false,
        'inactivity_timeout_minutes': settings['inactivityTimeoutMinutes'] ?? 5,
        'language': settings['language'] ?? 'en',
        'updated_at': settings['updatedAt'] ?? DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
