import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_currency.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/settings_supabase_data_source.dart';

// Settings State
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.biometricsEnabled = false,
    this.language = 'en',
    this.currencyCode = AppCurrency.defaultCode,
    this.updatedAt = '',
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool biometricsEnabled;
  final String language;
  final String currencyCode;
  final String updatedAt;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? biometricsEnabled,
    String? language,
    String? currencyCode,
    String? updatedAt,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      language: language ?? this.language,
      currencyCode: currencyCode ?? this.currencyCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'biometricsEnabled': biometricsEnabled,
      'language': language,
      'currencyCode': currencyCode,
      'updatedAt': updatedAt,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final modeName = json['themeMode'] as String?;

    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => ThemeMode.system,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      biometricsEnabled: json['biometricsEnabled'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      currencyCode: _normalizeCurrencyCode(
        json['currencyCode'] as String?,
      ),
      updatedAt: (json['updatedAt'] as String?)?.trim() ?? '',
    );
  }

  static String _normalizeCurrencyCode(String? value) {
    final code = value?.trim().toUpperCase() ?? AppCurrency.defaultCode;
    return AppCurrency.supportedCodes.contains(code)
        ? code
        : AppCurrency.defaultCode;
  }
}

final settingsSupabaseDataSourceProvider =
    Provider<SettingsSupabaseDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return null;
  }

  return SettingsSupabaseDataSource(client);
});

// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.localStorage, this.remoteDataSource)
      : super(const SettingsState()) {
    _loadSettings();
  }

  final LocalStorage localStorage;
  final SettingsSupabaseDataSource? remoteDataSource;
  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    AppLogger.lifecycle(
      'settings.load.start',
      tag: 'SettingsLifecycle',
      data: {
        'hasRemote': remoteDataSource != null,
      },
      level: 'debug',
    );

    try {
      final data = localStorage.getJson(_settingsKey);
      if (data != null) {
        state = SettingsState.fromJson(data);
        AppLogger.lifecycle(
          'settings.load.local_applied',
          tag: 'SettingsLifecycle',
          data: {
            'themeMode': state.themeMode.name,
            'language': state.language,
            'biometricsEnabled': state.biometricsEnabled,
          },
          level: 'debug',
        );
      }

      final remote = remoteDataSource;
      if (remote == null) {
        AppLogger.lifecycle(
          'settings.load.remote_unavailable',
          tag: 'SettingsLifecycle',
          level: 'warning',
        );
        return;
      }

      final remoteSettingsJson = await remote.fetchSettings();
      if (remoteSettingsJson == null) {
        if (_hasMeaningfulLocalState(state)) {
          await remote.upsertSettings(_toRemoteJson(state));
          AppLogger.lifecycle(
            'settings.sync.seed_remote_from_local',
            tag: 'SettingsLifecycle',
            level: 'info',
          );
        }
        return;
      }

      final remoteState = SettingsState.fromJson({
        ...remoteSettingsJson,
        'currencyCode': state.currencyCode,
      });
      if (_isRemoteNewer(remoteState, state)) {
        state = remoteState;
        await localStorage.setJson(_settingsKey, state.toJson());
        AppLogger.lifecycle(
          'settings.load.remote_newer_applied',
          tag: 'SettingsLifecycle',
          data: {
            'themeMode': state.themeMode.name,
            'language': state.language,
            'biometricsEnabled': state.biometricsEnabled,
          },
          level: 'info',
        );
      } else {
        await remote.upsertSettings(_toRemoteJson(state));
        AppLogger.lifecycle(
          'settings.sync.local_newer_pushed',
          tag: 'SettingsLifecycle',
          level: 'info',
        );
      }
    } catch (e) {
      AppLogger.lifecycle(
        'settings.load.failure',
        tag: 'SettingsLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
        },
        level: 'warning',
      );
      // If loading fails, keep default settings
    }
  }

  Future<void> _saveSettings() async {
    AppLogger.lifecycle(
      'settings.save.start',
      tag: 'SettingsLifecycle',
      data: {
        'themeMode': state.themeMode.name,
        'language': state.language,
        'biometricsEnabled': state.biometricsEnabled,
      },
      level: 'debug',
    );

    try {
      await localStorage.setJson(_settingsKey, state.toJson());

      final remote = remoteDataSource;
      if (remote != null) {
        await remote.upsertSettings(_toRemoteJson(state));
        AppLogger.lifecycle(
          'settings.save.remote_upsert_success',
          tag: 'SettingsLifecycle',
          level: 'success',
        );
      } else {
        AppLogger.lifecycle(
          'settings.save.remote_skipped',
          tag: 'SettingsLifecycle',
          level: 'debug',
        );
      }
    } catch (e) {
      AppLogger.lifecycle(
        'settings.save.failure',
        tag: 'SettingsLifecycle',
        data: {
          'errorType': e.runtimeType.toString(),
        },
        level: 'warning',
      );
      // Handle save error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(
      themeMode: mode,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(
      notificationsEnabled: enabled,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    state = state.copyWith(
      biometricsEnabled: enabled,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(
      language: language,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    state = state.copyWith(
      currencyCode: SettingsState._normalizeCurrencyCode(currencyCode),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  Future<void> clearAllData() async {
    // Clear all app data (cache, settings, etc.)
    await localStorage.clear();

    state = SettingsState(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _saveSettings();
  }

  bool _hasMeaningfulLocalState(SettingsState value) {
    return value.updatedAt.trim().isNotEmpty ||
        value.themeMode != ThemeMode.system ||
        value.notificationsEnabled != true ||
        value.biometricsEnabled != false ||
        value.language != 'en' ||
        value.currencyCode != AppCurrency.defaultCode;
  }

  Map<String, dynamic> _toRemoteJson(SettingsState value) {
    return {
      'themeMode': value.themeMode.name,
      'notificationsEnabled': value.notificationsEnabled,
      'biometricsEnabled': value.biometricsEnabled,
      'language': value.language,
      'updatedAt': value.updatedAt,
    };
  }

  bool _isRemoteNewer(SettingsState remote, SettingsState local) {
    final remoteTime = _parseIsoDate(remote.updatedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final localTime = _parseIsoDate(local.updatedAt) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return remoteTime.isAfter(localTime);
  }

  DateTime? _parseIsoDate(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    ref.watch(localStorageProvider),
    ref.watch(settingsSupabaseDataSourceProvider),
  );
});
