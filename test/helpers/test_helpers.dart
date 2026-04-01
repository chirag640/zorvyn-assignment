import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helpers for widget testing
class TestHelpers {
  TestHelpers._();
  
  /// Wrap widget with MaterialApp for testing
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }
  
  /// Pump widget with delays for animations
  static Future<void> pumpWithSettles(
    WidgetTester tester,
    Widget widget, [
    Duration duration = const Duration(seconds: 1),
  ]) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(duration);
  }
}

