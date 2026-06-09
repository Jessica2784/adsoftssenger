import 'dart:async';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note_model.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../services/conversacion_service.dart';
import '../../services/nota_service.dart';
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
  static List<NoteModel> _notesCache = const <NoteModel>[];

  final ConversacionService _conversacionService = ConversacionService();
  final NotaService _notaService = NotaService();

  late Future<List<_ConversationPreview>> _conversacionesFuture;
  late Future<List<NoteModel>> _notasFuture;
  late String _loadedUsuarioId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadedUsuarioId = widget.usuarioId?.toString() ?? '1';
    _conversacionesFuture = _loadConversaciones(_loadedUsuarioId);
    _notasFuture = _loadNotas();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshSilently();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _conversacionService.close();
    _notaService.close();
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
      _notasFuture = _loadNotas();
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
          child: Column(
            children: [
              _buildNotesStrip(context, session),
              Expanded(child: _buildConversationList(context)),
            ],
          ),
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
    final conversations =
        response.map(_ConversationPreview.fromJson).toList(growable: true)
          ..sort(_compareConversations);
    _conversationCache[usuarioId] = conversations;
    return conversations;
  }

  Future<List<NoteModel>> _loadNotas() async {
    final notes = await _notaService.obtenerNotasActivas();
    _notesCache = notes;
    return notes;
  }

  void _retryLoad() {
    setState(() {
      _conversacionesFuture = _loadConversaciones(_loadedUsuarioId);
      _notasFuture = _loadNotas();
    });
  }

  void _refreshSilently() {
    final usuarioId = _loadedUsuarioId;
    _conversacionService
        .obtenerConversacionesPorUsuario(usuarioId)
        .then((data) {
          if (!mounted || _loadedUsuarioId != usuarioId) return;
          final conversations =
              data.map(_ConversationPreview.fromJson).toList(growable: true)
                ..sort(_compareConversations);
          setState(() {
            _conversationCache[usuarioId] = conversations;
            _conversacionesFuture = Future.value(conversations);
          });
        })
        .catchError((error) {
          foundation.debugPrint(
            'No se pudo actualizar chats en polling: $error',
          );
        });

    _notaService
        .obtenerNotasActivas()
        .then((notes) {
          if (!mounted) return;
          setState(() {
            _notesCache = notes;
            _notasFuture = Future.value(notes);
          });
        })
        .catchError((error) {
          foundation.debugPrint(
            'No se pudieron actualizar notas en polling: $error',
          );
        });
  }

  int _compareConversations(_ConversationPreview a, _ConversationPreview b) {
    final aDate = a.fechaUltimoMensajeRaw;
    final bDate = b.fechaUltimoMensajeRaw;
    if (aDate == null && bDate == null) {
      return b.numericId.compareTo(a.numericId);
    }
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    final dateCompare = bDate.compareTo(aDate);
    if (dateCompare != 0) return dateCompare;
    return b.numericId.compareTo(a.numericId);
  }

  Widget _buildNotesStrip(BuildContext context, SessionProvider session) {
    return FutureBuilder<List<NoteModel>>(
      future: _notasFuture,
      builder: (context, snapshot) {
        final notes = snapshot.data ?? _notesCache;
        final currentUserId =
            int.tryParse(_loadedUsuarioId) ?? session.usuarioActualId;
        final ownNote = notes.cast<NoteModel?>().firstWhere(
          (note) => note?.usuarioId == currentUserId,
          orElse: () => null,
        );
        final visibleNotes = notes
            .where((note) => note.usuarioId != currentUserId)
            .toList(growable: false);

        return SizedBox(
          height: 124,
          child: Stack(
            children: [
              ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                itemCount: visibleNotes.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildMyNoteTile(context, session, ownNote);
                  }
                  return _buildNoteTile(
                    context,
                    visibleNotes[index - 1],
                    onTap: () => _openChatFromNote(visibleNotes[index - 1]),
                  );
                },
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  notes.isEmpty)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyNoteTile(
    BuildContext context,
    SessionProvider session,
    NoteModel? ownNote,
  ) {
    final currentUser = session.usuarioActual;
    final fallbackName = currentUser?.nombreMostrar ?? 'Tu nota';
    return _buildNoteTile(
      context,
      NoteModel(
        id: ownNote?.id ?? '0',
        usuarioId: int.tryParse(_loadedUsuarioId) ?? session.usuarioActualId,
        nombreMostrar: fallbackName,
        nombreUsuario: currentUser?.nombreUsuario ?? '',
        fotoPerfilUrl: currentUser?.fotoPerfilUrl ?? '',
        contenido: ownNote?.contenido ?? '+ nota',
        fechaCreacion: ownNote?.fechaCreacion,
      ),
      isMine: true,
      onTap: () => _showNoteDialog(ownNote),
    );
  }

  Widget _buildNoteTile(
    BuildContext context,
    NoteModel note, {
    required VoidCallback onTap,
    bool isMine = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 94,
        child: Column(
          children: [
            SizedBox(
              height: 82,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    name: note.nombreMostrar,
                    imageUrl: note.fotoPerfilUrl,
                    radius: 27,
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 88),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        note.contenido,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  if (isMine)
                    Positioned(
                      right: 18,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const SizedBox.square(
                          dimension: 20,
                          child: Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMine ? 'Tú' : note.nombreMostrar,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(NoteModel? ownNote) async {
    final controller = TextEditingController(text: ownNote?.contenido ?? '');
    final result = await showDialog<_NoteDialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu nota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(hintText: 'Escribe una nota corta'),
        ),
        actions: [
          if (ownNote != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const _NoteDialogResult.delete()),
              child: Text(
                'Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _NoteDialogResult.save(controller.text.trim()),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    if (result.delete) {
      await _deleteOwnNote(ownNote);
      return;
    }

    final contenido = result.content;
    if (contenido.isEmpty) return;
    try {
      await _notaService.crearNota(_loadedUsuarioId, contenido);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nota guardada.')));
      _retryLoad();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo guardar la nota.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteOwnNote(NoteModel? ownNote) async {
    if (ownNote == null) return;
    try {
      await _notaService.eliminarNota(ownNote.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nota eliminada.')));
      _retryLoad();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar la nota.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openChatFromNote(NoteModel note) async {
    try {
      final created = await _conversacionService.crearConversacion({
        'usuario1Id': int.tryParse(_loadedUsuarioId) ?? _loadedUsuarioId,
        'usuario2Id': note.usuarioId,
      });
      final conversation = _ConversationPreview.fromJson(created);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversacionId: conversation.id,
            usuarioActualId: _loadedUsuarioId,
            nombreContacto: note.nombreMostrar,
            fotoContactoUrl: note.fotoPerfilUrl,
          ),
        ),
      );
      if (mounted) _retryLoad();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo abrir la conversación.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
    return RefreshIndicator(
      onRefresh: () async {
        final conversations = await _loadConversaciones(_loadedUsuarioId);
        final notes = await _loadNotas();
        if (!mounted) return;
        setState(() {
          _conversacionesFuture = Future.value(conversations);
          _notasFuture = Future.value(notes);
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: conversations.length,
        itemBuilder: (context, index) =>
            _buildConversationTile(context, conversations[index]),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    _ConversationPreview conversation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const unreadColor = Color(0xFF31C759);
    final isUnread = conversation.tieneMensajesNoLeidos;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUnread
              ? unreadColor.withValues(alpha: 0.65)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
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
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          conversation.ultimoMensaje,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUnread
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        trailing: _buildTrailing(context, conversation),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  Future<void> _openConversation(_ConversationPreview conversation) async {
    unawaited(_markConversationRead(conversation.id));
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
  }

  Future<void> _markConversationRead(String conversationId) async {
    try {
      await _conversacionService.marcarComoLeida(
        conversationId,
        _loadedUsuarioId,
      );
    } catch (error) {
      foundation.debugPrint('No se pudo marcar chat como leído: $error');
    }
  }

  Widget _buildTrailing(
    BuildContext context,
    _ConversationPreview conversation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const unreadColor = Color(0xFF31C759);
    return SizedBox(
      width: 82,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.fechaUltimoMensaje.isNotEmpty)
            Text(
              conversation.fechaUltimoMensaje,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: conversation.tieneMensajesNoLeidos
                    ? unreadColor
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: conversation.tieneMensajesNoLeidos
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          if (conversation.tieneMensajesNoLeidos) ...[
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (conversation.cantidadMensajesNoLeidos > 1)
                  Text(
                    conversation.cantidadMensajesNoLeidos.toString(),
                    style: TextStyle(
                      color: unreadColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (conversation.cantidadMensajesNoLeidos > 1)
                  const SizedBox(width: 5),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: unreadColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ],
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

class _NoteDialogResult {
  final String content;
  final bool delete;

  const _NoteDialogResult.save(this.content) : delete = false;
  const _NoteDialogResult.delete() : content = '', delete = true;
}

class _ConversationPreview {
  final String id;
  final int numericId;
  final String nombreContacto;
  final String fotoContactoUrl;
  final String ultimoMensaje;
  final String fechaUltimoMensaje;
  final DateTime? fechaUltimoMensajeRaw;
  final bool tieneMensajesNoLeidos;
  final int cantidadMensajesNoLeidos;

  const _ConversationPreview({
    required this.id,
    required this.numericId,
    required this.nombreContacto,
    required this.fotoContactoUrl,
    required this.ultimoMensaje,
    required this.fechaUltimoMensaje,
    required this.fechaUltimoMensajeRaw,
    required this.tieneMensajesNoLeidos,
    required this.cantidadMensajesNoLeidos,
  });

  factory _ConversationPreview.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La conversacion recibida no es valida.');
    }
    final map = Map<String, dynamic>.from(json);
    final id = _requiredText(map['id'], 'id');
    final rawDate = _optionalText(map['fechaUltimoMensaje']);
    final parsedDate = DateTime.tryParse(rawDate)?.toLocal();
    return _ConversationPreview(
      id: id,
      numericId: int.tryParse(id) ?? 0,
      nombreContacto: _optionalText(
        map['nombreContacto'],
        fallback: 'Contacto sin nombre',
      ),
      fotoContactoUrl: _optionalText(map['fotoContactoUrl']),
      ultimoMensaje: _optionalText(
        map['ultimoMensaje'],
        fallback: 'Sin mensajes',
      ),
      fechaUltimoMensaje: _formatDate(rawDate, parsedDate),
      fechaUltimoMensajeRaw: parsedDate,
      tieneMensajesNoLeidos: _boolValue(map['tieneMensajesNoLeidos']),
      cantidadMensajesNoLeidos: _intValue(map['cantidadMensajesNoLeidos']),
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

  static bool _boolValue(Object? value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(String rawDate, DateTime? parsedDate) {
    if (rawDate.isEmpty) return '';
    if (parsedDate == null) return rawDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );
    if (messageDay == today) {
      final hour = parsedDate.hour % 12 == 0 ? 12 : parsedDate.hour % 12;
      final minute = parsedDate.minute.toString().padLeft(2, '0');
      final period = parsedDate.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    if (messageDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  }
}
