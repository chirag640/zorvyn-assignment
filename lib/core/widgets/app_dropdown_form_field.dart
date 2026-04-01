import 'package:flutter/material.dart';

import '../widgets/validation_ack_scope.dart';

// ────────────────────────────────────────────────────────────────────────────
// Global controller — ensures only one dropdown is open at a time
// ────────────────────────────────────────────────────────────────────────────

class _DropdownController {
  static _AppDropdownBodyState? _active;

  static void register(_AppDropdownBodyState d) {
    if (_active != null && _active != d) _active!._closeExternally();
    _active = d;
  }

  static void unregister(_AppDropdownBodyState d) {
    if (_active == d) _active = null;
  }

  static void closeActive() {
    _active?._closeExternally();
    _active = null;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Public form-field wrapper
// ────────────────────────────────────────────────────────────────────────────

/// An overlay-based dropdown that floats above the Scaffold, avoids
/// the keyboard, and adapts to the app's ThemeMode automatically.
///
/// Example:
/// ```dart
/// AppDropdownFormField<String>(
///   label: 'Country',
///   items: countries
///       .map((c) => DropdownMenuItem(value: c, child: Text(c)))
///       .toList(),
///   value: selectedCountry,
///   isRequired: true,
///   onChanged: (v) => setState(() => selectedCountry = v),
/// )
/// ```
class AppDropdownFormField<T> extends FormField<T> {
  AppDropdownFormField({
    super.key,
    required String label,
    required List<DropdownMenuItem<T>> items,
    T? value,
    FormFieldValidator<T>? validator,
    void Function(T?)? onChanged,
    String? hint,
    bool isRequired = true,
    IconData? prefixIcon,
    super.enabled,
    bool isLoading = false,
    double? maxHeight,
  }) : super(
          validator: isRequired && validator == null
              ? (v) => v == null ? 'Please select $label' : null
              : validator,
          initialValue: value,
          builder: (FormFieldState<T> state) {
            final ackScope = ValidationAckScope.maybeOf(state.context);
            if (ackScope != null &&
                ackScope.hideInlineErrors &&
                state.hasError &&
                state.errorText != null) {
              ackScope.controller.add(state.errorText!);
            }

            return _AppDropdownBody<T>(
              label: label,
              items: items,
              value: state.value,
              errorText: (ackScope?.hideInlineErrors ?? false)
                  ? null
                  : state.errorText,
              hint: hint,
              isRequired: isRequired,
              prefixIcon: prefixIcon,
              enabled: enabled,
              isLoading: isLoading,
              maxHeight: maxHeight,
              onChanged: (v) {
                state.didChange(v);
                onChanged?.call(v);
              },
            );
          },
        );
}

// ────────────────────────────────────────────────────────────────────────────
// Internal stateful body
// ────────────────────────────────────────────────────────────────────────────

class _AppDropdownBody<T> extends StatefulWidget {
  const _AppDropdownBody({
    required this.label,
    required this.items,
    required this.value,
    required this.errorText,
    required this.onChanged,
    this.hint,
    this.isRequired = false,
    this.prefixIcon,
    this.enabled = true,
    this.isLoading = false,
    this.maxHeight,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final String? errorText;
  final String? hint;
  final bool isRequired;
  final IconData? prefixIcon;
  final bool enabled;
  final bool isLoading;
  final double? maxHeight;
  final ValueChanged<T?> onChanged;

  @override
  State<_AppDropdownBody<T>> createState() => _AppDropdownBodyState<T>();
}

class _AppDropdownBodyState<T> extends State<_AppDropdownBody<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  final ScrollController _scroll = ScrollController();
  bool _expanded = false;
  bool _below = true;

  static const double _itemH = 48.0;
  static const double _maxFraction = 0.45;
  static const double _borderWidth = 2.0;
  static const double _radius = 10.0;

  // ── theme helpers ────────────────────────────────────────────────────────
  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _fill => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _text => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _hint => _isDark ? Colors.white38 : const Color(0xFF9E9E9E);
  Color get _border => _isDark ? Colors.white70 : Colors.black;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _activeBorder =>
      widget.errorText != null ? Theme.of(context).colorScheme.error : _border;

  void _toggle() {
    if (!widget.enabled || widget.isLoading || widget.items.isEmpty) return;
    if (_expanded) {
      _close();
    } else {
      _open();
    }
  }

  void _closeExternally() {
    if (_expanded) {
      _removeOverlay();
      if (mounted) setState(() => _expanded = false);
    }
  }

  void _open() {
    _DropdownController.register(this);
    _insertOverlay();
    setState(() => _expanded = true);
  }

  void _close() {
    _DropdownController.unregister(this);
    _removeOverlay();
    setState(() => _expanded = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _insertOverlay() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final size = box.size;
    final off = box.localToGlobal(Offset.zero);
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final kbH = mq.viewInsets.bottom;
    final topPad = mq.padding.top;

    final spaceBelow = screenH - (off.dy + size.height) - kbH - 4;
    final spaceAbove = off.dy - topPad - 4;
    final contentH = widget.items.length * _itemH;

    _below = spaceBelow >= contentH
        ? true
        : spaceAbove >= contentH
            ? false
            : spaceBelow >= spaceAbove;

    final maxH = widget.maxHeight ?? (screenH * _maxFraction);
    final available = _below ? spaceBelow : spaceAbove;
    final dynH = contentH.clamp(0.0, available).clamp(0.0, maxH);

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _DropdownController.closeActive,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: _below ? const Offset(0, -2) : const Offset(0, 2),
            targetAnchor: _below ? Alignment.bottomLeft : Alignment.topLeft,
            followerAnchor: _below ? Alignment.topLeft : Alignment.bottomLeft,
            child: SizedBox(
              width: size.width,
              height: dynH,
              child: Material(
                color: Colors.transparent,
                child: _buildList(dynH),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlay!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final idx = widget.items.indexWhere((i) => i.value == widget.value);
      if (idx != -1) {
        final target = (idx * _itemH)
            .clamp(0.0, _scroll.position.maxScrollExtent);
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _DropdownController.unregister(this);
    _removeOverlay();
    _scroll.dispose();
    super.dispose();
  }

  // ── header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final selected = widget.items.firstWhere(
      (i) => i.value == widget.value,
      orElse: () => DropdownMenuItem(value: null, child: const SizedBox()),
    );

    Widget display;
    if (widget.value == null || selected.value == null) {
      display = Text(
        widget.hint ?? widget.label,
        style: TextStyle(color: _hint, fontWeight: FontWeight.w600, fontSize: 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      final child = selected.child;
      final labelText = child is Text
          ? (child.data ?? child.textSpan?.toPlainText() ?? '')
          : null;
      display = labelText != null
          ? Text(
              labelText,
              style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          : DefaultTextStyle.merge(
              style: TextStyle(color: _text, fontSize: 16),
              child: child,
            );
    }

    // Border: drop bottom edge when expanded (merges visually with list)
    final border = _expanded
        ? Border(
            top: BorderSide(color: _activeBorder, width: _borderWidth),
            left: BorderSide(color: _activeBorder, width: _borderWidth),
            right: BorderSide(color: _activeBorder, width: _borderWidth),
            bottom: _below ? BorderSide.none : BorderSide(color: _activeBorder, width: _borderWidth),
          )
        : Border.all(color: _activeBorder, width: _borderWidth);

    final corners = BorderRadius.only(
      topLeft: const Radius.circular(_radius),
      topRight: const Radius.circular(_radius),
      bottomLeft: Radius.circular(_expanded && _below ? 0 : _radius),
      bottomRight: Radius.circular(_expanded && _below ? 0 : _radius),
    );

    return Container(
      height: 54,
      decoration: BoxDecoration(color: _fill, borderRadius: corners, border: border),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_accent),
                    ),
                  )
                : Icon(widget.prefixIcon, color: _text, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(child: display),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: _text, size: 24),
          ),
        ],
      ),
    );
  }

  // ── list ─────────────────────────────────────────────────────────────────

  Widget _buildList(double height) {
    final totalH = widget.items.length * _itemH;
    final needsScroll = totalH > height;

    final corners = BorderRadius.only(
      bottomLeft: Radius.circular(_below ? _radius : 0),
      bottomRight: Radius.circular(_below ? _radius : 0),
      topLeft: Radius.circular(_below ? 0 : _radius),
      topRight: Radius.circular(_below ? 0 : _radius),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: corners,
        border: Border.all(color: _border, width: _borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: needsScroll,
        child: ListView.separated(
          controller: _scroll,
          primary: false,
          shrinkWrap: true,
          physics: needsScroll
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => Divider(
            color: _border.withValues(alpha: 0.2),
            thickness: 1,
            height: 1,
          ),
          itemBuilder: (_, i) {
            final isSelected = widget.items[i].value == widget.value;
            return InkWell(
              onTap: () {
                widget.onChanged(widget.items[i].value);
                _close();
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: _itemH),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: isSelected ? _accent.withValues(alpha: 0.1) : Colors.transparent,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: isSelected ? _accent : _text,
                    fontSize: 15,
                  ),
                  child: widget.items[i].child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return CompositedTransformTarget(
      link: _link,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(onTap: _toggle, child: _buildHeader()),
              // Floating label on border
              Positioned(
                left: 12,
                top: -9,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: _fill,
                  child: widget.isRequired
                      ? RichText(
                          text: TextSpan(
                            text: widget.label,
                            style: TextStyle(
                              color: hasError
                                  ? Theme.of(context).colorScheme.error
                                  : _border,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          widget.label,
                          style: TextStyle(
                            color: hasError
                                ? Theme.of(context).colorScheme.error
                                : _border,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

