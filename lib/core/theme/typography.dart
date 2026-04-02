import 'package:flutter/material.dart';

TextTheme buildTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Rounded',
    ),
    headlineLarge: TextStyle(
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Rounded',
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Rounded',
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Text',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Text',
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: Color(0xFF86868B),
      fontFamily: 'SF Pro Text',
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: Color(0xFF86868B),
      fontFamily: 'SF Pro Text',
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1D1D1F),
      fontFamily: 'SF Pro Text',
    ),
  );
}
