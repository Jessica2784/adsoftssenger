import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../services/conversacion_service.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_detail.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.usuarioId});

  final Object? usuarioId;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static final Map<String, List<_ConversationPreview>> _conversationCache = {};

  final ConversacionService _conversacionService = ConversacionService();

  late Future<List<_ConversationPreview>> _conversacionesFuture;
  late String _loadedUsuarioId;

  @override
  void initState() {
    super.initState();
    _loadedUsuarioId = widget.usuarioId?.toString() ?? '1';
    _conversacionesFuture = _loadConversaciones(_loadedUsuarioId);
  }

  @override
  void dispose() {
    _conversacionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final usuarioId =
        widget.usuarioId?.toString() ?? session.usuarioActualId.toString();
    if (_loadedUsuarioId != usuarioId) {
      _loadedUsuarioId = usuarioId;
      _conversacionesFuture = _loadConversaciones(usuarioId);
    }
    final currentUser = session.usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ProfileAvatar(
            name: currentUser?.nombreMostrar ?? 'Jessica',
            imageUrl: currentUser?.fotoPerfilUrl ?? '',
            radius: 18,
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
          child: _buildConversationList(context),
        ),
      ),
    );
  }

  Future<List<_ConversationPreview>> _loadConversaciones(
    String usuarioId,
  ) async {
    foundation.debugPrint('Chats usuarioActualId usado: $usuarioId');
    final response = await _conversacionService.obtenerConversacionesPorUsuario(
      usuarioId,
    );
    final conversations = response
        .map(_ConversationPreview.fromJson)
        .toList(growable: false);
    _conversationCache[usuarioId] = conversations;
    return conversations;
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
        final cached = _conversationCache[_loadedUsuarioId];
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          if (cached != null && cached.isNotEmpty) {
            return Stack(
              children: [
                _buildConversationItems(context, cached),
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (cached != null && cached.isNotEmpty) {
            return Column(
              children: [
                MaterialBanner(
                  content: const Text(
                    'Se muestran los chats guardados. No se pudo actualizar.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: _retryLoad,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                Expanded(child: _buildConversationItems(context, cached)),
              ],
            );
          }
          return _buildErrorState(context, snapshot.error);
        }

        final conversaciones = snapshot.data ?? const <_ConversationPreview>[];
        if (conversaciones.isEmpty) return _buildEmptyState(context);
        return _buildConversationItems(context, conversaciones);
      },
    );
  }

  Widget _buildConversationItems(
    BuildContext context,
    List<_ConversationPreview> conversations,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: conversations.length,
      itemBuilder: (context, index) =>
          _buildConversationTile(context, conversations[index]),
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
        leading: ProfileAvatar(
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
        trailing: _buildTrailing(context, conversation.fechaUltimoMensaje),
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

  Widget _buildTrailing(BuildContext context, String time) {
    if (time.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 78,
      child: Text(
        time,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No hay conversaciones para mostrar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    final message = error is ApiException
        ? error.message
        : 'No se pudieron cargar las conversaciones.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
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
    if (messageDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }
}
