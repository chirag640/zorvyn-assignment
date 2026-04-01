import 'package:flutter/material.dart';

import 'typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
      brightness: Brightness.light,
      textTheme: buildTextTheme(),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF66AAFF),
        brightness: Brightness.dark,
      ),
      textTheme: buildTextTheme(),
    );
  }
}

