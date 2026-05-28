import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/dummy_data.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
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
