import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/storage/local_storage.dart';

// Settings State
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.biometricsEnabled = false,
    this.language = 'en',
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool biometricsEnabled;
  final String language;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? biometricsEnabled,
    String? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'biometricsEnabled': biometricsEnabled,
      'language': language,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      biometricsEnabled: json['biometricsEnabled'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
    );
  }
}

// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.localStorage) : super(const SettingsState()) {
    _loadSettings();
  }

  final LocalStorage localStorage;
  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    try {
      final data = localStorage.getJson(_settingsKey);
      if (data != null) {
        state = SettingsState.fromJson(data);
      }
    } catch (e) {
      // If loading fails, keep default settings
    }
  }

  Future<void> _saveSettings() async {
    try {
      await localStorage.setJson(_settingsKey, state.toJson());
    } catch (e) {
      // Handle save error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    state = state.copyWith(biometricsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> clearAllData() async {
    // Clear all app data (cache, settings, etc.)
    await localStorage.clear();
    state = const SettingsState();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(localStorageProvider));
});

