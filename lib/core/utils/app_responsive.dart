import 'package:flutter/material.dart';

/// Zero-dependency responsive utility.
///
/// Base design canvas: **390 × 844** (iPhone 14 Pro).
/// All scaling is proportional to the actual device screen size, so every
/// pixel value you pass is relative to that 390-wide mockup.
///
/// Quick-reference:
/// ```
/// AppResponsive.s(context, 16)   // scale a generic pixel value
/// AppResponsive.font(context, 16) // scale a font size
/// AppResponsive.p(context, 16)   // scale a padding value
/// AppResponsive.sh(context, 100) // scale based on HEIGHT ratio
/// context.rs(16)                 // shorthand via extension
/// context.rFont(16)
/// context.rVSpace(24)            // SizedBox(height: …) helper
/// ```
class AppResponsive {
  AppResponsive._();

  static const double _baseWidth = 390.0;
  static const double _baseHeight = 844.0;
  static const double _minScale = 0.9;
  static const double _maxScale = 1.25;
  static const double tabletContentMaxWidth = 760.0;
  static const double desktopContentMaxWidth = 980.0;

  static MediaQueryData _mq(BuildContext context) {
    final maybeMediaQuery = MediaQuery.maybeOf(context);
    if (maybeMediaQuery != null) {
      return maybeMediaQuery;
    }

    final view = View.maybeOf(context);
    if (view != null) {
      return MediaQueryData.fromView(view);
    }

    return const MediaQueryData(
      size: Size(_baseWidth, _baseHeight),
      textScaler: TextScaler.linear(1.0),
    );
  }

  // ── Breakpoints ────────────────────────────────────────────────────────────

  /// Any device narrower than this is considered a phone.
  static const double mobileBreak = 600.0;

  /// Devices at or above this width are considered desktop.
  static const double desktopBreak = 1200.0;

  // ── Raw percentage helpers ─────────────────────────────────────────────────

  /// Returns [percentage] * screenWidth.  e.g. `w(ctx, 0.5)` = 50% of width.
  static double w(BuildContext context, double percentage) =>
      _mq(context).size.width * percentage;

  /// Returns [percentage] * screenHeight.
  static double h(BuildContext context, double percentage) =>
      _mq(context).size.height * percentage;

  // ── Linear scaling ─────────────────────────────────────────────────────────

  /// Scales [px] linearly from the 390-wide base design to the actual screen.
  /// Use this for widths, icon sizes, spacers, and most widget dimensions.
  static double s(BuildContext context, double px) {
    return px * scaleFactor(context);
  }

  /// Scales [px] based on the screen HEIGHT ratio (844-base).
  /// Use for vertical paddings that must stay proportional on tall/short screens.
  static double sh(BuildContext context, double px) {
    final screenHeight = _mq(context).size.height;
    final raw = screenHeight / _baseHeight;
    final factor = raw.clamp(_minScale, _maxScale);
    return px * factor;
  }

  /// Returns a clamped width-based scale factor.
  static double scaleFactor(BuildContext context) {
    final screenWidth = _mq(context).size.width;
    final raw = screenWidth / _baseWidth;
    return raw.clamp(_minScale, _maxScale);
  }

  /// Returns a responsive text scale that combines system preference and device width.
  static TextScaler textScaler(BuildContext context) {
    final mediaQuery = _mq(context);
    final systemFactor = mediaQuery.textScaler.scale(1.0);
    final adaptive = (systemFactor * scaleFactor(context)).clamp(0.9, 1.4);
    return TextScaler.linear(adaptive);
  }

  /// Returns a route-level max width for centered layouts on larger screens.
  static double contentMaxWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: tabletContentMaxWidth,
      desktop: desktopContentMaxWidth,
    );
  }

  // ── Named semantic wrappers ────────────────────────────────────────────────

  /// Scale a font size. Delegates to [s] (width-ratio scaling).
  static double font(BuildContext context, double px) => s(context, px);

  /// Scale a padding / margin value.
  static double p(BuildContext context, double px) => s(context, px);

  /// Scale a border radius.
  static double radius(BuildContext context, double px) => s(context, px);

  /// Scale an icon size.
  static double icon(BuildContext context, double px) => s(context, px);

  /// Scale a border / divider thickness.
  static double thickness(BuildContext context, double px) => s(context, px);

  // ── EdgeInsets helpers ─────────────────────────────────────────────────────

  /// Returns scaled [EdgeInsets].
  ///
  /// Pass [all] for uniform insets, or individual sides for asymmetric insets.
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) return EdgeInsets.all(s(context, all));
    return EdgeInsets.only(
      left: s(context, left ?? horizontal ?? 0),
      top: s(context, top ?? vertical ?? 0),
      right: s(context, right ?? horizontal ?? 0),
      bottom: s(context, bottom ?? vertical ?? 0),
    );
  }

  /// Returns symmetric scaled [EdgeInsets].
  static EdgeInsets paddingSymmetric(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(
        horizontal: s(context, horizontal),
        vertical: s(context, vertical),
      );

  // ── BorderRadius helpers ───────────────────────────────────────────────────

  /// Returns [BorderRadius.circular] with a scaled radius.
  static BorderRadius borderRadius(BuildContext context, double px) =>
      BorderRadius.circular(radius(context, px));

  // ── SizedBox gap helpers ───────────────────────────────────────────────────

  /// Returns a [SizedBox] with a responsive **width** for horizontal gaps.
  static SizedBox horizontalSpace(BuildContext context, double px) =>
      SizedBox(width: s(context, px));

  /// Returns a [SizedBox] with a responsive **height** for vertical gaps.
  static SizedBox verticalSpace(BuildContext context, double px) =>
      SizedBox(height: s(context, px));

  // ── Device-type detection ──────────────────────────────────────────────────

  /// `true` when the shortest side is ≥ 600 dp (tablet).
  static bool isTablet(BuildContext context) =>
      _mq(context).size.shortestSide >= mobileBreak;

  /// `true` when width ≥ 1200 dp (desktop / large tablet landscape).
  static bool isDesktop(BuildContext context) =>
      _mq(context).size.width >= desktopBreak;

  /// Returns the current [AppDeviceType] based on screen width.
  static AppDeviceType deviceType(BuildContext context) {
    final w = _mq(context).size.width;
    if (w >= desktopBreak) return AppDeviceType.desktop;
    if (w >= mobileBreak) return AppDeviceType.tablet;
    return AppDeviceType.mobile;
  }

  // ── Responsive value picker ────────────────────────────────────────────────

  /// Returns different values for mobile / tablet / desktop.
  /// Falls back to narrower variants when broader ones are null.
  ///
  /// ```dart
  /// final cols = AppResponsive.value(context, mobile: 2, tablet: 3, desktop: 4);
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType(context)) {
      case AppDeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case AppDeviceType.tablet:
        return tablet ?? mobile;
      case AppDeviceType.mobile:
        return mobile;
    }
  }
}

/// Device-type enum used by [AppResponsive.deviceType].
enum AppDeviceType { mobile, tablet, desktop }

/// Centers and constrains content width for large screens while keeping
/// full-width behavior on phones.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final routeMaxWidth =
            maxWidth ?? AppResponsive.contentMaxWidth(context);
        final resolvedMaxWidth = routeMaxWidth.isFinite
            ? routeMaxWidth.clamp(0.0, constraints.maxWidth).toDouble()
            : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ── BuildContext extension ────────────────────────────────────────────────────

/// Convenience extension so you can write `context.rs(16)` instead of
/// `AppResponsive.s(context, 16)`.
extension ResponsiveContext on BuildContext {
  // ── theme helpers (keep from original ContextExtensions) ────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  MediaQueryData get mediaQuery =>
      MediaQuery.maybeOf(this) ?? MediaQueryData.fromView(View.of(this));
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ── backward-compat aliases (match old ContextExtensions) ───────────────
  /// @deprecated Use [screenWidth] instead.
  double get width => screenWidth;

  /// @deprecated Use [screenHeight] instead.
  double get height => screenHeight;

  // ── snackbar helper ──────────────────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }

  // ── device type ─────────────────────────────────────────────────────────
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isDesktop => AppResponsive.isDesktop(this);
  AppDeviceType get deviceType => AppResponsive.deviceType(this);
  double get rScale => AppResponsive.scaleFactor(this);
  double get rContentMaxWidth => AppResponsive.contentMaxWidth(this);
  TextScaler get rTextScaler => AppResponsive.textScaler(this);

  // ── scaling helpers ──────────────────────────────────────────────────────
  /// Scale a pixel value (width-ratio).
  double rs(double px) => AppResponsive.s(this, px);

  /// Scale a pixel value (height-ratio).
  double rsh(double px) => AppResponsive.sh(this, px);

  /// Scale a font size.
  double rFont(double px) => AppResponsive.font(this, px);

  /// Scale a padding / margin value.
  double rPadding(double px) => AppResponsive.p(this, px);

  /// Scale a border radius.
  double rRadius(double px) => AppResponsive.radius(this, px);

  /// Scale an icon size.
  double rIcon(double px) => AppResponsive.icon(this, px);

  /// Scale a border thickness.
  double rThickness(double px) => AppResponsive.thickness(this, px);

  // ── EdgeInsets helpers ───────────────────────────────────────────────────
  EdgeInsets rPaddingAll(double px) => AppResponsive.padding(this, all: px);
  EdgeInsets rPaddingH(double px) =>
      AppResponsive.padding(this, horizontal: px);
  EdgeInsets rPaddingV(double px) => AppResponsive.padding(this, vertical: px);
  EdgeInsets rPaddingSymmetric({double h = 0, double v = 0}) =>
      AppResponsive.paddingSymmetric(this, horizontal: h, vertical: v);

  // ── BorderRadius ─────────────────────────────────────────────────────────
  BorderRadius rBorderRadius(double px) => AppResponsive.borderRadius(this, px);

  // ── SizedBox gap helpers ─────────────────────────────────────────────────
  SizedBox rHSpace(double px) => AppResponsive.horizontalSpace(this, px);
  SizedBox rVSpace(double px) => AppResponsive.verticalSpace(this, px);

  // ── responsive value picker ──────────────────────────────────────────────
  T rValue<T>({required T mobile, T? tablet, T? desktop}) =>
      AppResponsive.value(this,
          mobile: mobile, tablet: tablet, desktop: desktop);

  Widget rContent({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
  }) {
    return ResponsiveContent(
      padding: padding,
      maxWidth: maxWidth,
      child: child,
    );
  }
}
