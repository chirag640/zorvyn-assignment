import 'package:flutter/material.dart';

class ZorvynLogo extends StatelessWidget {
  const ZorvynLogo({
    super.key,
    this.size = 72,
    this.borderRadius,
    this.semanticLabel,
    this.fit = BoxFit.cover,
  });

  final double size;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo/logo.png',
      width: size,
      height: size,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      filterQuality: FilterQuality.high,
    );

    if (borderRadius == null) {
      return logo;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: logo,
    );
  }
}
