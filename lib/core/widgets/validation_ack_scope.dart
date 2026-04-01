import 'package:flutter/material.dart';

/// Accumulates validation error messages from descendant form fields.
///
/// Usage:
/// ```dart
/// final _controller = ValidationAckController();
///
/// ValidationAckScope(
///   controller: _controller,
///   hideInlineErrors: true,
///   child: Form(
///     key: _formKey,
///     child: Column(children: [...]),
///   ),
/// );
///
/// // On submit:
/// _controller.clear();
/// if (_formKey.currentState!.validate()) { ... }
/// final errors = _controller.errors; // show banner
/// ```
class ValidationAckScope extends InheritedWidget {
  const ValidationAckScope({
    super.key,
    required this.controller,
    required super.child,
    this.hideInlineErrors = false,
  });

  final ValidationAckController controller;

  /// When true, descendant fields suppress their inline error text and instead
  /// push the message into [controller].
  final bool hideInlineErrors;

  static ValidationAckScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ValidationAckScope>();

  @override
  bool updateShouldNotify(ValidationAckScope oldWidget) =>
      oldWidget.controller != controller ||
      oldWidget.hideInlineErrors != hideInlineErrors;
}

/// Controller that collects validation error strings from form fields.
class ValidationAckController extends ChangeNotifier {
  final List<String> _errors = [];

  List<String> get errors => List.unmodifiable(_errors);

  bool get hasErrors => _errors.isNotEmpty;

  void add(String error) {
    _errors.add(error);
    notifyListeners();
  }

  void clear() {
    _errors.clear();
    notifyListeners();
  }
}

