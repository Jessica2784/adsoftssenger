import 'package:flutter/material.dart';

import '../../models/story_model.dart';
import '../../services/api_service.dart';
import '../../services/historia_service.dart';
import '../../widgets/profile_avatar.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.story,
    required this.usuarioActualId,
  });

  final StoryModel story;
  final int usuarioActualId;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final HistoriaService _historiaService = HistoriaService();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.story.propia && !widget.story.vista) {
      _markViewed();
    }
  }

  Future<void> _markViewed() async {
    try {
      await _historiaService.marcarVista(
        widget.story.id,
        widget.usuarioActualId,
      );
    } catch (_) {
      // La historia sigue visible aunque el registro de vista falle.
    }
  }

  @override
  void dispose() {
    _historiaService.close();
    super.dispose();
  }

  Future<void> _deleteStory() async {
    if (_deleting) return;
    setState(() => _deleting = true);

    try {
      await _historiaService.eliminarHistoria(
        widget.story.id,
        widget.usuarioActualId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = error is HistoriaNoDisponibleException
          ? error.message
          : error is ApiException
          ? error.message
          : 'No se pudo eliminar la historia.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              name: widget.story.nombreMostrar,
              imageUrl: widget.story.fotoPerfilUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.story.propia
                        ? 'Tu historia'
                        : widget.story.nombreMostrar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _relativeTime(widget.story.fechaPublicacion),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.story.propia)
            IconButton(
              tooltip: 'Eliminar historia',
              onPressed: _deleting ? null : _deleteStory,
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            ApiService.resolveMediaUrl(widget.story.imagenUrl),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No se pudo cargar esta historia.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    return 'Hace ${difference.inHours} h';
  }
}
