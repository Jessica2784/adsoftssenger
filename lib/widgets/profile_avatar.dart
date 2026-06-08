import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.showUnseenRing = false,
  });

  final String name;
  final String imageUrl;
  final double radius;
  final bool showOnlineIndicator;
  final bool showUnseenRing;

  @override
  Widget build(BuildContext context) {
    Widget avatar = SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(child: _buildImage(context)),
    );

    if (showUnseenRing) {
      avatar = Container(
        padding: EdgeInsets.all(radius * 0.1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0A84FF), width: 2.5),
        ),
        child: avatar,
      );
    }

    if (!showOnlineIndicator) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.36,
            height: radius * 0.36,
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

  Widget _buildImage(BuildContext context) {
    final resolvedUrl = ApiService.resolveMediaUrl(imageUrl);
    if (resolvedUrl.isEmpty) return _fallback(context);

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty
        ? '?'
        : trimmedName.characters.first.toUpperCase();

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: radius * 0.72,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
