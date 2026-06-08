import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/dummy_data.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/mensaje_service.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/user_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  final User contact;
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.contact,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Message> get _messages => DummyData.chatMessages[widget.chatId] ?? [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, String> _reactions = {};

  @override
  void initState() {
    super.initState();
    DummyData.markRead(widget.chatId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      DummyData.addMessage(
        widget.chatId,
        text: text,
        time: TimeOfDay.now().format(context),
      );
    });

    _controller.clear();
  }

  Future<void> _sendImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1600,
      );
      if (pickedImage == null) return;

      final imageBytes = await pickedImage.readAsBytes();
      if (!mounted) return;

      setState(() {
        DummyData.addImageMessage(
          widget.chatId,
          imageBytes: imageBytes,
          imageName: pickedImage.name,
          time: TimeOfDay.now().format(context),
        );
      });
    } catch (_) {
      if (!mounted) return;
      final sourceName = source == ImageSource.camera
          ? 'la cámara'
          : 'la galería';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir $sourceName. Revisa los permisos del dispositivo.',
          ),
        ),
      );
    }
  }

  void _addReaction(String messageId, String emoji) {
    setState(() {
      _reactions[messageId] = emoji;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: widget.contact, radius: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.contact.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final Message message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMine = DummyData.isMine(message);
    final sender = DummyData.userById(message.senderId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth > 720
            ? 520.0
            : constraints.maxWidth * 0.78;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () async {
              final emoji = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Reaccionar'),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final emoji in [
                          '👍',
                          '😂',
                          '😍',
                          '😮',
                          '😢',
                          '😡',
                        ])
                          IconButton(
                            onPressed: () => Navigator.pop(context, emoji),
                            icon: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
              if (emoji != null) _addReaction(message.id, emoji);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          sender.name,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (message.hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          message.imageBytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 160,
                                alignment: Alignment.center,
                                color: colorScheme.surface,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                        ),
                      ),
                      if (message.text.trim().isNotEmpty)
                        const SizedBox(height: 8),
                    ],
                    if (message.text.trim().isNotEmpty)
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMine
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.time,
                          style: TextStyle(
                            color: isMine
                                ? colorScheme.onPrimary.withValues(alpha: 0.75)
                                : colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (_reactions[message.id] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _reactions[message.id]!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInputArea() {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;

                  final iconDensity = isCompact
                      ? VisualDensity.compact
                      : VisualDensity.standard;

                  return Row(
                    children: [
                      IconButton(
                        tooltip: 'Tomar foto',
                        visualDensity: iconDensity,
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _sendImage(ImageSource.camera),
                      ),
                      IconButton(
                        tooltip: 'Enviar imagen',
                        visualDensity: iconDensity,
                        icon: const Icon(Icons.photo),
                        onPressed: () => _sendImage(ImageSource.gallery),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Aa',
                            isDense: true,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversacionId;
  final String usuarioActualId;
  final String nombreContacto;
  final String? fotoContactoUrl;

  const ChatScreen({
    super.key,
    required this.conversacionId,
    required this.usuarioActualId,
    required this.nombreContacto,
    this.fotoContactoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MensajeService _mensajeService = MensajeService();
  final ImagePicker _backendImagePicker = ImagePicker();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_BackendMessage> _messages = [];
  Timer? _refreshTimer;
  Object? _loadError;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSending = false;

  bool get _canSend => _controller.text.trim().isNotEmpty && !_isSending;

  @override
  void initState() {
    super.initState();
    _loadMessages(showLoading: true, forceScroll: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    _mensajeService.close();
    super.dispose();
  }

  Future<List<_BackendMessage>> _fetchMessages() async {
    final response = await _mensajeService.obtenerMensajesPorConversacion(
      widget.conversacionId,
    );

    final messagesById = <String, _BackendMessage>{};
    for (final item in response) {
      final message = _BackendMessage.fromJson(item);
      messagesById[message.id] = message;
    }

    final messages = messagesById.values.toList(growable: false);
    messages.sort((a, b) {
      final aDate = a.fechaEnvio;
      final bDate = b.fechaEnvio;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return -1;
      if (bDate == null) return 1;
      return aDate.compareTo(bDate);
    });

    return messages;
  }

  Future<void> _loadMessages({
    bool showLoading = false,
    bool forceScroll = false,
  }) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final messages = await _fetchMessages();
      if (!mounted) return;

      final shouldScroll =
          forceScroll || _messages.isEmpty || _hasNewMessages(messages);

      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _loadError = null;
        _isLoading = false;
      });

      if (shouldScroll) {
        _scrollToBottom();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  bool _hasNewMessages(List<_BackendMessage> messages) {
    final currentIds = _messages.map((message) => message.id).toSet();
    return messages.any((message) => !currentIds.contains(message.id));
  }

  void _reloadMessages() {
    _loadMessages(forceScroll: true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final contenido = _controller.text.trim();
    if (contenido.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _mensajeService.enviarMensaje({
        'contenido': contenido,
        'tipoMensaje': 'TEXTO',
        'remitenteId': widget.usuarioActualId,
        'conversacionId': widget.conversacionId,
        'estado': 'ENVIADO',
      });

      _controller.clear();
      await _loadMessages(forceScroll: true);
    } catch (error) {
      if (!mounted) return;

      final message = error is ApiException
          ? error.message
          : 'No se pudo enviar el mensaje.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isSending) return;

    final image = await _backendImagePicker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 82,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (image == null || !mounted) return;

    setState(() => _isSending = true);
    try {
      await _mensajeService.enviarImagen(
        conversacionId: widget.conversacionId,
        remitenteId: widget.usuarioActualId,
        bytes: await image.readAsBytes(),
        filename: image.name,
        contentType: _imageMimeType(image),
      );
      await _loadMessages(forceScroll: true);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo enviar la foto.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _imageMimeType(XFile image) {
    final reported = image.mimeType?.trim();
    if (reported != null && reported.isNotEmpty) return reported;
    final lower = image.name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showMessageImage(_BackendMessage message) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                ApiService.resolveMediaUrl(message.urlAdjunto),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              name: widget.nombreContacto,
              imageUrl: widget.fotoContactoUrl ?? '',
              radius: 18,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.nombreContacto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _messages.isEmpty) {
      return _buildErrorState(_loadError);
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(_messages[index]);
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_BackendMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMine = message.remitenteId == widget.usuarioActualId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth > 720
            ? 520.0
            : constraints.maxWidth * 0.78;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        message.remitenteNombre.isEmpty
                            ? widget.nombreContacto
                            : message.remitenteNombre,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (message.hasImage) ...[
                    GestureDetector(
                      onTap: () => _showMessageImage(message),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 180,
                            maxWidth: 420,
                            maxHeight: 420,
                          ),
                          child: Image.network(
                            ApiService.resolveMediaUrl(message.urlAdjunto),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const SizedBox(
                                    width: 220,
                                    height: 180,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 220,
                              height: 120,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (!message.hasImage || message.contenido != 'Foto')
                    Text(
                      message.contenido,
                      style: TextStyle(
                        color: isMine
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.fechaEnvioTexto,
                        style: TextStyle(
                          color: isMine
                              ? colorScheme.onPrimary.withValues(alpha: 0.75)
                              : colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (isMine && message.estado.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          message.estado,
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomInputArea() {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Tomar foto',
                    onPressed: _isSending
                        ? null
                        : () => _pickAndSendImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  IconButton(
                    tooltip: 'Elegir foto de la galería',
                    onPressed: _isSending
                        ? null
                        : () => _pickAndSendImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Aa',
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Enviar',
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _canSend ? _sendMessage : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No hay mensajes en esta conversacion.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = error is ApiException
        ? error.message
        : 'No se pudieron cargar los mensajes.';

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
              onPressed: _reloadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendMessage {
  final String id;
  final String contenido;
  final String tipoMensaje;
  final DateTime? fechaEnvio;
  final String fechaEnvioTexto;
  final String remitenteId;
  final String remitenteNombre;
  final String conversacionId;
  final String urlAdjunto;
  final String estado;

  const _BackendMessage({
    required this.id,
    required this.contenido,
    required this.tipoMensaje,
    required this.fechaEnvio,
    required this.fechaEnvioTexto,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.conversacionId,
    required this.urlAdjunto,
    required this.estado,
  });

  factory _BackendMessage.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('El mensaje recibido no es valido.');
    }

    final map = Map<String, dynamic>.from(json);
    final rawDate = _text(map['fechaEnvio']);
    final parsedDate = DateTime.tryParse(rawDate)?.toLocal();

    return _BackendMessage(
      id: _text(
        map['id'],
        fallback: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      contenido: _text(map['contenido']),
      tipoMensaje: _text(map['tipoMensaje'], fallback: 'TEXTO'),
      fechaEnvio: parsedDate,
      fechaEnvioTexto: _formatDate(rawDate, parsedDate),
      remitenteId: _text(map['remitenteId']),
      remitenteNombre: _text(map['remitenteNombre']),
      conversacionId: _text(map['conversacionId']),
      urlAdjunto: _text(map['urlAdjunto']),
      estado: _text(map['estado']),
    );
  }

  bool get hasImage => tipoMensaje == 'IMAGEN_URL' && urlAdjunto.isNotEmpty;

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
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

    final hour = parsedDate.hour % 12 == 0 ? 12 : parsedDate.hour % 12;
    final minute = parsedDate.minute.toString().padLeft(2, '0');
    final period = parsedDate.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (messageDay == today) return time;
    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Ayer $time';
    }

    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} $time';
  }
}
