import 'package:adsoftssenger/data/dummy_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat previews use the last real message', () {
    for (final chat in DummyData.chats) {
      final messages = DummyData.chatMessages[chat.id];
      if (messages == null || messages.isEmpty) continue;

      expect(DummyData.lastMessageFor(chat), messages.last.text);
      expect(DummyData.lastTimeFor(chat), messages.last.time);
    }
  });

  test('switching profiles changes message ownership', () {
    final originalUser = DummyData.currentUser;
    addTearDown(() => DummyData.switchProfile(originalUser));

    final carlos = DummyData.userById('2');
    final carlosChat = DummyData.chats.firstWhere((chat) => chat.id == 'c2');
    final lastMessage = DummyData.chatMessages[carlosChat.id]!.last;

    DummyData.switchProfile(originalUser);
    expect(DummyData.isMine(lastMessage), isFalse);

    DummyData.switchProfile(carlos);
    expect(DummyData.isMine(lastMessage), isTrue);
  });

  test('unread state is tracked for the active profile only', () {
    final originalUser = DummyData.currentUser;
    final chat = DummyData.chats.firstWhere((chat) => chat.id == 'c1');
    final originalUnreadUsers = Set<String>.of(chat.unreadForUserIds);

    addTearDown(() {
      DummyData.switchProfile(originalUser);
      chat.unreadForUserIds
        ..clear()
        ..addAll(originalUnreadUsers);
      chat.isRead = !chat.hasUnreadFor(DummyData.currentUser.id);
    });

    DummyData.switchProfile(DummyData.userById('0'));
    expect(DummyData.hasUnread(chat), isTrue);

    DummyData.markRead(chat.id);
    expect(DummyData.hasUnread(chat), isFalse);
  });
}
