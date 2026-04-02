import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.size = 80,
    this.onTap,
  });

  final String? avatarUrl;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderWidth = (size * 0.025).clamp(2.0, 4.0);
    final shadowBlur = (size * 0.08).clamp(8.0, 16.0);
    final shadowOffset = (size * 0.03).clamp(3.0, 8.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: borderWidth.toDouble(),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: shadowBlur.toDouble(),
              offset: Offset(0, shadowOffset.toDouble()),
            ),
          ],
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(context);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholder(context);
                  },
                )
              : _buildPlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
