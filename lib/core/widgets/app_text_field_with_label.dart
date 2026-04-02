import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_responsive.dart';
import '../widgets/validation_ack_scope.dart';

/// A polished text field with a floating label that clips the border.
///
/// The label floats to the top border when the field is focused or has text.
/// Supports required-field asterisk, password toggle, error messages, and
/// adapts automatically to the app's ThemeMode (light / dark).
///
/// Example:
/// ```dart
/// AppTextFieldWithLabel(
///   controller: _emailCtrl,
///   label: 'Email Address',
///   keyboardType: TextInputType.emailAddress,
///   isRequired: true,
///   validator: Validators.email,
/// )
/// ```
class AppTextFieldWithLabel extends StatefulWidget {
  const AppTextFieldWithLabel({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.onChanged,
    this.isRequired = false,
    this.maxLength,
    this.counterText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final void Function(String)? onChanged;
  final bool isRequired;
  final int? maxLength;
  final String? counterText;
  final bool autofocus;

  @override
  State<AppTextFieldWithLabel> createState() => _AppTextFieldWithLabelState();
}

class _AppTextFieldWithLabelState extends State<AppTextFieldWithLabel> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    widget.controller.addListener(_rebuild);
    _obscured = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});
  void _onFocusChange() => setState(() => _isFocused = _focusNode.hasFocus);

  // ── theme-aware colours ────────────────────────────────────────────────────
  Color _borderColor(BuildContext context, {required bool hasError}) {
    if (hasError) return Theme.of(context).colorScheme.error;
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black;
  }

  Color _focusedBorderColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  Color _labelColor(BuildContext context, {required bool hasError}) => hasError
      ? Theme.of(context).colorScheme.error
      : _borderColor(context, hasError: false);

  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A1A1A);

  Color _hintColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white38
          : const Color(0xFF9E9E9E);

  Color _fillColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  @override
  Widget build(BuildContext context) {
    final ackScope = ValidationAckScope.maybeOf(context);

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator != null
          ? (_) => widget.validator!(widget.controller.text)
          : null,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;
        final errorText = state.errorText;

        // Propagate error to ValidationAckScope if present
        if (ackScope != null && ackScope.hideInlineErrors) {
          if (hasError && errorText != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => ackScope.controller.add(errorText),
            );
          }
        }

        final showInlineError =
            hasError && !(ackScope?.hideInlineErrors ?? false);
        final activeBorderColor = _isFocused
            ? _focusedBorderColor(context)
            : _borderColor(context, hasError: hasError);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // ── field container ───────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _fillColor(context),
                    borderRadius: BorderRadius.circular(context.rRadius(10)),
                    border: Border.all(
                      color: activeBorderColor,
                      width: context.rThickness(2),
                    ),
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    keyboardType: widget.keyboardType,
                    maxLines: widget.obscureText ? 1 : widget.maxLines,
                    minLines: widget.maxLines == 1 ? null : 1,
                    obscureText: widget.obscureText && _obscured,
                    enabled: widget.enabled,
                    inputFormatters: widget.inputFormatters,
                    textInputAction: widget.textInputAction,
                    onFieldSubmitted: widget.onFieldSubmitted,
                    autofillHints: widget.autofillHints,
                    maxLength: widget.maxLength,
                    onChanged: (v) {
                      state.didChange(v);
                      widget.onChanged?.call(v);
                    },
                    cursorColor: _textColor(context),
                    style: TextStyle(
                      color: _textColor(context),
                      fontSize: context.rFont(16),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      // Show hint/placeholder label only when unfocused and empty
                      label: (!_isFocused && widget.controller.text.isEmpty)
                          ? _buildLabel(
                              widget.hintText ?? widget.label,
                              context: context,
                              floating: false,
                              hasError: false,
                            )
                          : null,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintStyle: TextStyle(color: _hintColor(context)),
                      filled: true,
                      fillColor: _fillColor(context),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.rs(12),
                        vertical: context.rs(14),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(context.rRadius(10)),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(context.rRadius(10)),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(context.rRadius(10)),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(context.rRadius(10)),
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(context.rRadius(10)),
                        borderSide: BorderSide.none,
                      ),
                      // Suppress built-in error — we draw it ourselves
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: _buildSuffixIcon(context),
                      counterText: widget.counterText,
                    ),
                  ),
                ),
                // ── floating label clipped to border ──────────────────────
                if (!widget.readOnly &&
                    (_isFocused || widget.controller.text.isNotEmpty))
                  Positioned(
                    left: context.rs(12),
                    top: -context.rs(9),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: context.rs(4)),
                      color: _fillColor(context),
                      child: _buildLabel(
                        widget.label,
                        context: context,
                        floating: true,
                        hasError: hasError,
                      ),
                    ),
                  ),
              ],
            ),
            // ── inline error ───────────────────────────────────────────────
            if (showInlineError && errorText != null)
              Padding(
                padding: EdgeInsets.only(
                  left: context.rs(12),
                  top: context.rs(4),
                ),
                child: Text(
                  errorText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: context.rFont(12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(
    String text, {
    required BuildContext context,
    required bool floating,
    required bool hasError,
  }) {
    final color = _labelColor(context, hasError: hasError);
    final style = TextStyle(
      color: floating ? color : _hintColor(context),
      fontSize: floating ? context.rFont(11) : context.rFont(16),
      fontWeight: FontWeight.w600,
    );

    if (widget.isRequired) {
      return RichText(
        text: TextSpan(
          text: text,
          style: style,
          children: [
            TextSpan(
              text: ' *',
              style: style.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }
    return Text(text, style: style);
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (widget.obscureText) {
      return GestureDetector(
        onTap: () => setState(() => _obscured = !_obscured),
        child: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: context.rIcon(22),
          color: _hintColor(context),
        ),
      );
    }
    return null;
  }
}
