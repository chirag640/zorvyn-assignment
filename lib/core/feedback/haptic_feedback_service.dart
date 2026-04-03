import 'package:flutter/services.dart';

class HapticFeedbackService {
  const HapticFeedbackService._();

  static Future<void> light() {
    return HapticFeedback.lightImpact();
  }

  static Future<void> medium() {
    return HapticFeedback.mediumImpact();
  }

  static Future<void> success() {
    return HapticFeedback.selectionClick();
  }

  static Future<void> error() {
    return HapticFeedback.heavyImpact();
  }
}
