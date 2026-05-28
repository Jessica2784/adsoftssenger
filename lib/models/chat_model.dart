class Chat {
  final String id;
  final List<String> participantIds;
  final Set<String> unreadForUserIds;
  String lastMessage;
  String time;
  bool isRead;

  Chat({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.time,
    this.isRead = false,
    Set<String>? unreadForUserIds,
  }) : unreadForUserIds = unreadForUserIds ?? <String>{};

  bool includesUser(String userId) => participantIds.contains(userId);

  bool hasUnreadFor(String userId) => unreadForUserIds.contains(userId);
}
