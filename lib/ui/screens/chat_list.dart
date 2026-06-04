import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/conversacion_service.dart';
import '../../widgets/user_avatar.dart';
import 'chat_detail.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.usuarioId});

  final Object? usuarioId;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ConversacionService _conversacionService = ConversacionService();

  late Future<List<_ConversationPreview>> _conversacionesFuture;
  late String _loadedUsuarioId;

  @override
  void initState() {
    super.initState();
    _loadedUsuarioId = _resolveUsuarioId();
    _conversacionesFuture = _loadConversaciones(_loadedUsuarioId);
  }

  @override
  void dispose() {
    _conversacionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = _resolveUsuarioId();
    if (_loadedUsuarioId != usuarioId) {
      _loadedUsuarioId = usuarioId;
      _conversacionesFuture = _loadConversaciones(usuarioId);
    }

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
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _retryLoad,
          ),
        ],
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
              Expanded(child: _buildConversationList(context)),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveUsuarioId() {
    return '1';
  }

  Future<List<_ConversationPreview>> _loadConversaciones(
    String usuarioId,
  ) async {
    foundation.debugPrint('Chats usuarioActualId usado: $usuarioId');

    final response = await _conversacionService.obtenerConversacionesPorUsuario(
      usuarioId,
    );

    return response.map(_ConversationPreview.fromJson).toList(growable: false);
  }

  void _retryLoad() {
    setState(() {
      _conversacionesFuture = _loadConversaciones(_loadedUsuarioId);
    });
  }

  Widget _buildConversationList(BuildContext context) {
    return FutureBuilder<List<_ConversationPreview>>(
      future: _conversacionesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error);
        }

        final conversaciones = snapshot.data ?? const <_ConversationPreview>[];
        if (conversaciones.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
          itemCount: conversaciones.length,
          itemBuilder: (context, index) {
            return _buildConversationTile(context, conversaciones[index]);
          },
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    _ConversationPreview conversation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        minVerticalPadding: 12,
        leading: _ConversationAvatar(
          name: conversation.nombreContacto,
          imageUrl: conversation.fotoContactoUrl,
          radius: 25,
        ),
        title: Text(
          conversation.nombreContacto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          conversation.ultimoMensaje,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: _buildTrailing(
          context,
          time: conversation.fechaUltimoMensaje,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversacionId: conversation.id,
                usuarioActualId: _loadedUsuarioId,
                nombreContacto: conversation.nombreContacto,
                fotoContactoUrl: conversation.fotoContactoUrl,
              ),
            ),
          );

          if (mounted) _retryLoad();
        },
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, {required String time}) {
    if (time.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 78,
      child: Text(
        time,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No hay conversaciones para mostrar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = error is ApiException
        ? error.message
        : 'No se pudieron cargar las conversaciones.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
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

class _ConversationPreview {
  final String id;
  final String nombreContacto;
  final String fotoContactoUrl;
  final String ultimoMensaje;
  final String fechaUltimoMensaje;

  const _ConversationPreview({
    required this.id,
    required this.nombreContacto,
    required this.fotoContactoUrl,
    required this.ultimoMensaje,
    required this.fechaUltimoMensaje,
  });

  factory _ConversationPreview.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La conversacion recibida no es valida.');
    }

    final map = Map<String, dynamic>.from(json);

    return _ConversationPreview(
      id: _requiredText(map['id'], 'id'),
      nombreContacto: _optionalText(
        map['nombreContacto'],
        fallback: 'Contacto sin nombre',
      ),
      fotoContactoUrl: _optionalText(map['fotoContactoUrl']),
      ultimoMensaje: _optionalText(
        map['ultimoMensaje'],
        fallback: 'Sin mensajes',
      ),
      fechaUltimoMensaje: _formatDate(map['fechaUltimoMensaje']),
    );
  }

  static String _requiredText(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('La conversacion no tiene $fieldName.');
    }
    return text;
  }

  static String _optionalText(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatDate(Object? value) {
    final rawDate = value?.toString().trim() ?? '';
    if (rawDate.isEmpty) return '';

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return rawDate;

    final localDate = parsedDate.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(localDate.year, localDate.month, localDate.day);

    if (messageDay == today) {
      final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
      final minute = localDate.minute.toString().padLeft(2, '0');
      final period = localDate.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.name,
    required this.imageUrl,
    required this.radius,
  });

  final String name;
  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();

    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: trimmedUrl.isEmpty
            ? _fallback(context)
            : Image.network(
                trimmedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _fallback(context),
              ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name
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
