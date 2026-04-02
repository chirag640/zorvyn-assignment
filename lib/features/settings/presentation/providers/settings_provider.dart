import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/datasources/settings_supabase_data_source.dart';

// Settings State
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.biometricsEnabled = false,
    this.language = 'en',
    this.updatedAt = '',
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool biometricsEnabled;
  final String language;
  final String updatedAt;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? biometricsEnabled,
    String? language,
    String? updatedAt,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      language: language ?? this.language,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'biometricsEnabled': biometricsEnabled,
      'language': language,
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
      updatedAt: (json['updatedAt'] as String?)?.trim() ?? '',
    );
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
    try {
      final data = localStorage.getJson(_settingsKey);
      if (data != null) {
        state = SettingsState.fromJson(data);
      }

      final remote = remoteDataSource;
      if (remote == null) {
        return;
      }

      final remoteSettingsJson = await remote.fetchSettings();
      if (remoteSettingsJson == null) {
        if (_hasMeaningfulLocalState(state)) {
          await remote.upsertSettings(state.toJson());
        }
        return;
      }

      final remoteState = SettingsState.fromJson(remoteSettingsJson);
      if (_isRemoteNewer(remoteState, state)) {
        state = remoteState;
        await localStorage.setJson(_settingsKey, state.toJson());
      } else {
        await remote.upsertSettings(state.toJson());
      }
    } catch (e) {
      // If loading fails, keep default settings
    }
  }

  Future<void> _saveSettings() async {
    try {
      await localStorage.setJson(_settingsKey, state.toJson());

      final remote = remoteDataSource;
      if (remote != null) {
        await remote.upsertSettings(state.toJson());
      }
    } catch (e) {
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
        value.language != 'en';
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
