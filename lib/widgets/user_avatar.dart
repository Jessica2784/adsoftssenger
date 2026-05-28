import 'package:flutter/material.dart';

import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.showStatusRing = false,
  });

  final User user;
  final double radius;
  final bool showOnlineIndicator;
  final bool showStatusRing;

  @override
  Widget build(BuildContext context) {
    Widget avatar = SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(child: _buildImage(context)),
    );

    if (showStatusRing && user.hasStatuses) {
      avatar = Container(
        padding: EdgeInsets.all(radius * 0.08),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _statusRingColor(context), width: 2.4),
        ),
        child: avatar,
      );
    }

    if (!showOnlineIndicator) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.35,
              height: radius * 0.35,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _statusRingColor(BuildContext context) {
    if (user.hasPhotoStatus) return const Color(0xFF0A84FF);
    return Theme.of(context).colorScheme.outlineVariant;
  }

  Widget _buildImage(BuildContext context) {
    if (user.avatarBytes != null) {
      return Image.memory(
        user.avatarBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    return Image.network(
      user.profileUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: radius * 0.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
