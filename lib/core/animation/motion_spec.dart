import 'package:flutter/animation.dart';

enum MotionTier { micro, standard, large }

class MotionSpec {
  const MotionSpec._();

  static const Duration microDuration = Duration(milliseconds: 160);
  static const Duration standardDuration = Duration(milliseconds: 260);
  static const Duration largeDuration = Duration(milliseconds: 420);

  static Duration duration(
    MotionTier tier, {
    required bool reduceMotion,
  }) {
    if (reduceMotion) {
      return Duration.zero;
    }

    switch (tier) {
      case MotionTier.micro:
        return microDuration;
      case MotionTier.standard:
        return standardDuration;
      case MotionTier.large:
        return largeDuration;
    }
  }

  static Curve curve(MotionTier tier) {
    switch (tier) {
      case MotionTier.micro:
        return Curves.easeOut;
      case MotionTier.standard:
        return Curves.easeOutCubic;
      case MotionTier.large:
        return Curves.easeOutQuart;
    }
  }
}
