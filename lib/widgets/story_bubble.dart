import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'user_avatar.dart';

class StoryBubble extends StatelessWidget {
  const StoryBubble({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            UserAvatar(user: user, radius: 28, showOnlineIndicator: false),
            const SizedBox(height: 6),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
