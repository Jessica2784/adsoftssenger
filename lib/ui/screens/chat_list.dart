import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import 'chat_detail.dart';
import 'new_chat_dialog.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chats = DummyData.visibleChats;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: UserAvatar(
            user: DummyData.currentUser,
            radius: 18,
            showStatusRing: true,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  children: [
                    for (final user in DummyData.activeUsers.take(4))
                      _buildStory(user: user),
                    _buildStory(user: DummyData.currentUser, name: 'Tú'),
                  ],
                ),
              ),
              Expanded(
                child: chats.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final Chat chat = chats[index];
                          final User contact = DummyData.contactFor(chat);
                          final hasUnread = DummyData.hasUnread(chat);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: hasUnread
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      )
                                    : colorScheme.outlineVariant.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                            child: ListTile(
                              minVerticalPadding: 12,
                              leading: UserAvatar(
                                user: contact,
                                radius: 25,
                                showStatusRing: true,
                              ),
                              title: Text(
                                contact.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                DummyData.lastMessageFor(chat),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasUnread
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              trailing: _buildTrailing(
                                context,
                                time: DummyData.lastTimeFor(chat),
                                hasUnread: hasUnread,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      contact: contact,
                                      chatId: chat.id,
                                    ),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const NewChatDialog(),
          );
          if (created == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add_comment),
        label: const Text('Nuevo chat'),
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context, {
    required String time,
    required bool hasUnread,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Este perfil todavía no tiene conversaciones.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildStory({required User user, String? name}) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = user.latestStatus;
    final statusText = status != null && status.hasNote
        ? status.note.trim()
        : null;

    return SizedBox(
      width: 94,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: status == null
                  ? const SizedBox.shrink()
                  : Container(
                      constraints: const BoxConstraints(maxWidth: 82),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status.hasImage
                            ? const Color(0xFFE7F1FF)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status.hasImage
                              ? const Color(0xFF0A84FF)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                      ),
                      child: statusText == null || statusText.isEmpty
                          ? Icon(
                              Icons.photo,
                              size: 18,
                              color: status.hasImage
                                  ? const Color(0xFF0A84FF)
                                  : colorScheme.onSurfaceVariant,
                            )
                          : Text(
                              statusText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: status.hasImage
                                    ? const Color(0xFF0758B8)
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
            ),
            const SizedBox(height: 4),
            UserAvatar(user: user, radius: 27, showStatusRing: true),
            const SizedBox(height: 6),
            Text(
              name ?? user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
