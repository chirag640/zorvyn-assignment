import 'package:flutter/material.dart';

import '../utils/app_responsive.dart';

/// Reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.message,
  });
  
  final double size;
  final Color? color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scaledSize = context.rs(size);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: scaledSize,
            height: scaledSize,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            context.rVSpace(16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

