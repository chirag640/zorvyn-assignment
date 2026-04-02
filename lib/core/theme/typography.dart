import 'package:flutter/material.dart';

TextTheme buildTextTheme({
  required Color primaryTextColor,
  required Color secondaryTextColor,
}) {
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: primaryTextColor,
      fontFamily: 'SF Pro Rounded',
    ),
    headlineLarge: TextStyle(
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: primaryTextColor,
      fontFamily: 'SF Pro Rounded',
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: primaryTextColor,
      fontFamily: 'SF Pro Rounded',
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: primaryTextColor,
      fontFamily: 'SF Pro Text',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: primaryTextColor,
      fontFamily: 'SF Pro Text',
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: secondaryTextColor,
      fontFamily: 'SF Pro Text',
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: secondaryTextColor,
      fontFamily: 'SF Pro Text',
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: primaryTextColor,
      fontFamily: 'SF Pro Text',
    ),
  );
}
