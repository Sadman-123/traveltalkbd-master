import 'package:flutter/material.dart';
import 'package:traveltalkbd/diy_components/traveltalktheme.dart';

/// Reusable user avatar - shows profile photo, initials, or placeholder.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? initials;
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.initials,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _buildPlaceholder(size),
              )
            : _buildPlaceholder(size),
      ),
    );
  }

  Widget _buildPlaceholder(double s) {
    if (initials != null && initials!.isNotEmpty) {
      return Container(
        color: AppColors.primary.withOpacity(0.3),
        alignment: Alignment.center,
        child: Text(
          initials!.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: s * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: Icon(
        Icons.person,
        size: s * 0.6,
        color: AppColors.primary,
      ),
    );
  }
}
