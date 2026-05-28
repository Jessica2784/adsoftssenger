import 'dart:typed_data';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class DummyData {
  static final List<User> profiles = [
    User(
      id: '0',
      name: 'Jessica',
      profileUrl: 'https://i.pravatar.cc/150?img=1',
      isOnline: true,
      description: 'Perfil principal',
      statusNote: 'Trabajando en Adsoftssenger',
    ),
    User(
      id: '1',
      name: 'Adolfo',
      profileUrl: 'https://i.pravatar.cc/150?img=11',
      isOnline: true,
      statusNote: 'En clase',
    ),
    User(
      id: '2',
      name: 'Carlos',
      profileUrl: 'https://i.pravatar.cc/150?img=12',
      isOnline: true,
    ),
    User(
      id: '3',
      name: 'María',
      profileUrl: 'https://i.pravatar.cc/150?img=5',
      isOnline: false,
      statusNote: 'Estudiando para el examen',
    ),
    User(
      id: '4',
      name: 'Lucía',
      profileUrl: 'https://i.pravatar.cc/150?img=15',
      isOnline: true,
    ),
    User(
      id: '5',
      name: 'Pedro',
      profileUrl: 'https://i.pravatar.cc/150?img=18',
      isOnline: false,
      statusNote: 'Disponible al rato',
    ),
    User(
      id: '6',
      name: 'Sofía',
      profileUrl: 'https://i.pravatar.cc/150?img=20',
      isOnline: true,
    ),
    User(
      id: '7',
      name: 'Tomás',
      profileUrl: 'https://i.pravatar.cc/150?img=22',
      isOnline: false,
    ),
    User(
      id: '8',
      name: 'Valentina',
      profileUrl: 'https://i.pravatar.cc/150?img=25',
      isOnline: true,
    ),
  ];

  static User currentUser = profiles.first;

  static List<User> get activeUsers => profiles
      .where((user) => user.id != currentUser.id)
      .toList(growable: false);

  static List<Chat> get visibleChats => chats
      .where((chat) => chat.includesUser(currentUser.id))
      .toList(growable: false);

  static final List<Chat> chats = [
    Chat(
      id: 'c1',
      participantIds: ['0', '1'],
      lastMessage: '¿Ya quedó el diagrama de arquitectura?',
      time: '11:30 AM',
      isRead: false,
      unreadForUserIds: {'0'},
    ),
    Chat(
      id: 'c2',
      participantIds: ['0', '2'],
      lastMessage: 'Nos vemos en la facultad más tarde.',
      time: 'Ayer',
      isRead: true,
    ),
    Chat(
      id: 'c3',
      participantIds: ['0', '3'],
      lastMessage: '¿Tienes el apunte de hoy?',
      time: '10:15 AM',
      isRead: false,
      unreadForUserIds: {'0'},
    ),
    Chat(
      id: 'c4',
      participantIds: ['0', '4'],
      lastMessage: '¡Nos vemos en la cafetería!',
      time: '09:50 AM',
      isRead: true,
    ),
    Chat(
      id: 'c5',
      participantIds: ['0', '5'],
      lastMessage: '¿Jugamos esta noche?',
      time: 'Ayer',
      isRead: false,
      unreadForUserIds: {'0'},
    ),
    Chat(
      id: 'c6',
      participantIds: ['0', '6'],
      lastMessage: '¡Feliz cumple! 🎉',
      time: 'Ayer',
      isRead: true,
    ),
    Chat(
      id: 'c7',
      participantIds: ['0', '7'],
      lastMessage: '¿Me ayudas con el TP?',
      time: '08:00 AM',
      isRead: false,
      unreadForUserIds: {'0'},
    ),
    Chat(
      id: 'c8',
      participantIds: ['0', '8'],
      lastMessage: '¡Gracias por la ayuda!',
      time: '07:45 AM',
      isRead: true,
    ),
  ];

  static final Map<String, List<Message>> chatMessages = {
    'c1': [
      Message(
        id: 'c1-m1',
        text: 'Hola Adolfo, ¿cómo vas con la maquetación?',
        senderId: '0',
        time: '11:25 AM',
      ),
      Message(
        id: 'c1-m2',
        text: 'Todo bien, ya tengo la lista de chats cableada.',
        senderId: '1',
        time: '11:27 AM',
      ),
      Message(
        id: 'c1-m3',
        text: 'Excelente, revisamos la UI al rato.',
        senderId: '0',
        time: '11:29 AM',
      ),
      Message(
        id: 'c1-m4',
        text: '¿Ya quedó el diagrama de arquitectura?',
        senderId: '1',
        time: '11:30 AM',
      ),
    ],
    'c2': [
      Message(
        id: 'c2-m1',
        text: '¿Nos vemos en la facultad?',
        senderId: '0',
        time: 'Ayer',
      ),
      Message(
        id: 'c2-m2',
        text: 'Sí, a las 5 en la entrada.',
        senderId: '2',
        time: 'Ayer',
      ),
      Message(
        id: 'c2-m3',
        text: 'Nos vemos en la facultad más tarde.',
        senderId: '2',
        time: 'Ayer',
      ),
    ],
    'c3': [
      Message(
        id: 'c3-m1',
        text: 'Hola María, ¿qué tema vieron hoy?',
        senderId: '0',
        time: '10:12 AM',
      ),
      Message(
        id: 'c3-m2',
        text: '¿Tienes el apunte de hoy?',
        senderId: '3',
        time: '10:15 AM',
      ),
    ],
    'c4': [
      Message(
        id: 'c4-m1',
        text: 'Ya terminé la práctica.',
        senderId: '0',
        time: '09:45 AM',
      ),
      Message(
        id: 'c4-m2',
        text: '¡Nos vemos en la cafetería!',
        senderId: '4',
        time: '09:50 AM',
      ),
    ],
    'c5': [
      Message(
        id: 'c5-m1',
        text: 'Tengo libre después de clase.',
        senderId: '0',
        time: 'Ayer',
      ),
      Message(
        id: 'c5-m2',
        text: '¿Jugamos esta noche?',
        senderId: '5',
        time: 'Ayer',
      ),
    ],
    'c6': [
      Message(
        id: 'c6-m1',
        text: 'Gracias por acordarte.',
        senderId: '0',
        time: 'Ayer',
      ),
      Message(
        id: 'c6-m2',
        text: '¡Feliz cumple! 🎉',
        senderId: '6',
        time: 'Ayer',
      ),
    ],
    'c7': [
      Message(
        id: 'c7-m1',
        text: 'Sí, dime qué necesitas revisar.',
        senderId: '0',
        time: '07:58 AM',
      ),
      Message(
        id: 'c7-m2',
        text: '¿Me ayudas con el TP?',
        senderId: '7',
        time: '08:00 AM',
      ),
    ],
    'c8': [
      Message(
        id: 'c8-m1',
        text: 'Me sirvió mucho lo que explicaste.',
        senderId: '0',
        time: '07:40 AM',
      ),
      Message(
        id: 'c8-m2',
        text: '¡Gracias por la ayuda!',
        senderId: '8',
        time: '07:45 AM',
      ),
    ],
  };

  static User userById(String userId) {
    return profiles.firstWhere(
      (user) => user.id == userId,
      orElse: () => currentUser,
    );
  }

  static User contactFor(Chat chat) {
    final otherId = chat.participantIds.firstWhere(
      (userId) => userId != currentUser.id,
      orElse: () => currentUser.id,
    );
    return userById(otherId);
  }

  static String lastMessageFor(Chat chat) {
    final messages = chatMessages[chat.id];
    if (messages == null || messages.isEmpty) return chat.lastMessage;
    final lastMessage = messages.last;
    if (lastMessage.hasImage && lastMessage.text.trim().isEmpty) {
      return 'Foto';
    }
    return lastMessage.text;
  }

  static String lastTimeFor(Chat chat) {
    final messages = chatMessages[chat.id];
    if (messages == null || messages.isEmpty) return chat.time;
    return messages.last.time;
  }

  static bool isMine(Message message) => message.senderId == currentUser.id;

  static bool hasUnread(Chat chat) => chat.hasUnreadFor(currentUser.id);

  static void markRead(String chatId) {
    final index = chats.indexWhere((chat) => chat.id == chatId);
    if (index == -1) return;

    chats[index]
      ..unreadForUserIds.remove(currentUser.id)
      ..isRead = !chats[index].hasUnreadFor(currentUser.id);
  }

  static void addProfile(User user) {
    profiles.add(user);
  }

  static void switchProfile(User user) {
    currentUser = user;
  }

  static Chat? findChatWith(String userId) {
    for (final chat in chats) {
      if (chat.includesUser(currentUser.id) && chat.includesUser(userId)) {
        return chat;
      }
    }
    return null;
  }

  static Chat createChatWith({
    required User contact,
    required String text,
    required String time,
  }) {
    final existingChat = findChatWith(contact.id);
    if (existingChat != null) {
      if (text.isNotEmpty) addMessage(existingChat.id, text: text, time: time);
      return existingChat;
    }

    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      participantIds: [currentUser.id, contact.id],
      lastMessage: text.isEmpty ? 'Nuevo chat' : text,
      time: time,
      isRead: true,
    );

    chats.insert(0, chat);
    chatMessages[chat.id] = [];
    if (text.isNotEmpty) addMessage(chat.id, text: text, time: time);
    return chat;
  }

  static Message addMessage(
    String chatId, {
    required String text,
    required String time,
    Uint8List? imageBytes,
    String? imageName,
  }) {
    final message = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      senderId: currentUser.id,
      time: time,
      imageBytes: imageBytes,
      imageName: imageName,
    );

    chatMessages[chatId] ??= [];
    chatMessages[chatId]!.add(message);
    _syncChatPreview(
      chatId,
      text: message.hasImage && text.trim().isEmpty ? 'Foto' : text,
      time: time,
    );
    return message;
  }

  static Message addImageMessage(
    String chatId, {
    required Uint8List imageBytes,
    required String imageName,
    required String time,
    String text = '',
  }) {
    return addMessage(
      chatId,
      text: text,
      time: time,
      imageBytes: imageBytes,
      imageName: imageName,
    );
  }

  static void _syncChatPreview(
    String chatId, {
    required String text,
    required String time,
  }) {
    final index = chats.indexWhere((chat) => chat.id == chatId);
    if (index == -1) return;

    final chat = chats[index]
      ..lastMessage = text
      ..time = time
      ..unreadForUserIds.remove(currentUser.id);

    for (final userId in chat.participantIds) {
      if (userId != currentUser.id) {
        chat.unreadForUserIds.add(userId);
      }
    }

    chat.isRead = !chat.hasUnreadFor(currentUser.id);

    if (index > 0) {
      chats
        ..removeAt(index)
        ..insert(0, chat);
    }
  }
}
