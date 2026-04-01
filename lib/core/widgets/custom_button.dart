import 'package:flutter/material.dart';

import '../utils/app_responsive.dart';

/// Custom button with loading state
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });
  
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(context),
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(context),
    );
  }
  
  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: context.rs(20),
        width: context.rs(20),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.rIcon(20)),
          context.rHSpace(8),
          Text(text),
        ],
      );
    }
    
    return Text(text);
  }
}

