import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class FeatureFlagsState {
  const FeatureFlagsState({
    this.enhancedAnimations = true,
    this.forecastCards = true,
    this.netWorthEnabled = true,
    this.recurringDetectionEnabled = true,
    this.billsTrackerEnabled = true,
  });

  final bool enhancedAnimations;
  final bool forecastCards;
  final bool netWorthEnabled;
  final bool recurringDetectionEnabled;
  final bool billsTrackerEnabled;

  FeatureFlagsState copyWith({
    bool? enhancedAnimations,
    bool? forecastCards,
    bool? netWorthEnabled,
    bool? recurringDetectionEnabled,
    bool? billsTrackerEnabled,
  }) {
    return FeatureFlagsState(
      enhancedAnimations: enhancedAnimations ?? this.enhancedAnimations,
      forecastCards: forecastCards ?? this.forecastCards,
      netWorthEnabled: netWorthEnabled ?? this.netWorthEnabled,
      recurringDetectionEnabled:
          recurringDetectionEnabled ?? this.recurringDetectionEnabled,
      billsTrackerEnabled: billsTrackerEnabled ?? this.billsTrackerEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enhancedAnimations': enhancedAnimations,
      'forecastCards': forecastCards,
      'netWorthEnabled': netWorthEnabled,
      'recurringDetectionEnabled': recurringDetectionEnabled,
      'billsTrackerEnabled': billsTrackerEnabled,
    };
  }

  factory FeatureFlagsState.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsState(
      enhancedAnimations: json['enhancedAnimations'] as bool? ?? true,
      forecastCards: json['forecastCards'] as bool? ?? true,
      netWorthEnabled: json['netWorthEnabled'] as bool? ?? true,
      recurringDetectionEnabled:
          json['recurringDetectionEnabled'] as bool? ?? true,
      billsTrackerEnabled: json['billsTrackerEnabled'] as bool? ?? true,
    );
  }
}

class FeatureFlagsNotifier extends StateNotifier<FeatureFlagsState> {
  FeatureFlagsNotifier(this._ref) : super(const FeatureFlagsState()) {
    _load();
  }

  final Ref _ref;
  static const String _flagsKey = 'feature_flags_v1';

  Future<void> _load() async {
    final localStorage = _ref.read(localStorageProvider);
    final json = localStorage.getJson(_flagsKey);
    if (json == null) {
      return;
    }

    state = FeatureFlagsState.fromJson(json);
  }

  Future<void> _save(FeatureFlagsState next) async {
    final localStorage = _ref.read(localStorageProvider);
    state = next;
    await localStorage.setJson(_flagsKey, next.toJson());
  }

  Future<void> setEnhancedAnimations(bool value) {
    return _save(state.copyWith(enhancedAnimations: value));
  }
}

final featureFlagsProvider =
    StateNotifierProvider<FeatureFlagsNotifier, FeatureFlagsState>((ref) {
  return FeatureFlagsNotifier(ref);
});
