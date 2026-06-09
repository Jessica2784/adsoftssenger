import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/api_user.dart';
import '../../models/note_model.dart';
import '../../models/story_model.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../services/conversacion_service.dart';
import '../../services/historia_service.dart';
import '../../services/media_service.dart';
import '../../services/nota_service.dart';
import '../../services/usuario_service.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/profile_avatar.dart';
import 'chat_detail.dart';
import 'register_user_screen.dart';
import 'story_viewer_screen.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();
  final ConversacionService _conversacionService = ConversacionService();
  final HistoriaService _historiaService = HistoriaService();
  final MediaService _mediaService = MediaService();
  final NotaService _notaService = NotaService();
  final ImagePicker _imagePicker = ImagePicker();

  List<ApiUser> _users = [];
  List<StoryModel> _stories = [];
  List<NoteModel> _notes = [];
  Object? _usersError;
  Object? _storiesError;
  int _selectedView = 0;
  int? _openingUserId;
  int? _deletingStoryId;
  bool _isSearching = false;
  bool _usersLoading = true;
  bool _storiesLoading = false;
  bool _storyUploading = false;

  int get _usuarioActualId => context.read<SessionProvider>().usuarioActualId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usuarioService.close();
    _conversacionService.close();
    _historiaService.close();
    _mediaService.close();
    _notaService.close();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _usersLoading = true;
        _usersError = null;
      });
    }

    try {
      final usuarioId = _usuarioActualId;
      final response = await _usuarioService.obtenerUsuarios();
      final users = response.map(ApiUser.fromJson).toList()
        ..sort((a, b) => a.nombreMostrar.compareTo(b.nombreMostrar));
      if (!mounted) return;

      for (final user in users) {
        if (user.id == usuarioId) {
          context.read<SessionProvider>().sincronizarUsuario(user);
          break;
        }
      }

      setState(() {
        _users = users;
        _usersLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _usersError = error;
        _usersLoading = false;
      });
    }
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _notaService.obtenerNotasActivas();
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (error) {
      debugPrint('No se pudieron cargar notas en Personas: $error');
    }
  }

  Future<void> _loadStories() async {
    if (mounted) {
      setState(() {
        _storiesLoading = true;
        _storiesError = null;
      });
    }

    try {
      final currentUserId = _usuarioActualId;
      final response = await _mediaService.getStories();
      final stories = response
          .map(StoryModel.fromJson)
          .map(
            (story) => story.copyWith(
              propia: story.propia || story.usuarioId == currentUserId,
            ),
          )
          .where((story) => story.imagenUrl.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _stories = stories;
        _storiesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _storiesError = error;
        _storiesLoading = false;
      });
    }
  }

  void _refreshCurrentView() {
    _loadNotes();
    if (_selectedView == 0) {
      _loadUsers();
    } else {
      _loadStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filterUsers(_contactUsers, _searchController.text);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar contacto',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text(
                'Personas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentView,
          ),
          if (_selectedView == 0)
            IconButton(
              tooltip: _isSearching ? 'Cerrar busqueda' : 'Buscar contacto',
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.people),
                      label: Text('Contactos'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.auto_stories),
                      label: Text('Estados'),
                    ),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (selection) {
                    final selectedView = selection.first;
                    setState(() {
                      _selectedView = selectedView;
                      if (_selectedView == 1) {
                        _isSearching = false;
                        _searchController.clear();
                      }
                    });
                    if (selectedView == 1) {
                      _loadStories();
                      _loadNotes();
                    }
                  },
                  showSelectedIcon: false,
                ),
              ),
              Expanded(child: _buildCurrentView(contacts)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedView == 0
            ? _openRegisterUser
            : _storyUploading
            ? null
            : _uploadStory,
        icon: _storyUploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_selectedView == 0 ? Icons.person_add : Icons.add_a_photo),
        label: Text(_selectedView == 0 ? 'Agregar usuario' : 'Subir historia'),
      ),
    );
  }

  List<ApiUser> get _contactUsers => _users
      .where((user) => user.id != _usuarioActualId)
      .toList(growable: false);

  Widget _buildCurrentView(List<ApiUser> contacts) {
    if (_selectedView == 1) return _buildStoriesView();

    if (_usersLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_usersError != null && _users.isEmpty) {
      return _buildErrorState(
        _usersError,
        'No se pudieron cargar las personas.',
        _loadUsers,
      );
    }
    return _buildContactsList(contacts);
  }

  Future<void> _openRegisterUser() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
    );
    if (created != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario creado correctamente.')),
    );
    await _loadUsers();
  }

  Future<void> _uploadStory() async {
    if (_storyUploading) return;
    final image = await pickImageFromCameraOrGallery(
      context,
      picker: _imagePicker,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    setState(() => _storyUploading = true);
    try {
      await _mediaService.uploadStoryImage(_usuarioActualId, File(image.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historia subida correctamente.')),
      );
      await _loadStories();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo subir la historia. Intenta de nuevo.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _storyUploading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  List<ApiUser> _filterUsers(List<ApiUser> users, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return users;
    return users
        .where((user) {
          return '${user.nombreMostrar} ${user.nombreUsuario}'
              .toLowerCase()
              .contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<void> _openChat(ApiUser contact) async {
    if (_openingUserId != null) return;
    setState(() => _openingUserId = contact.id);

    try {
      final conversation = await _obtenerOCrearConversacion(contact);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversacionId: conversation.id,
            usuarioActualId: _usuarioActualId.toString(),
            nombreContacto: contact.nombreMostrar,
            fotoContactoUrl: contact.fotoPerfilUrl,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo abrir la conversacion.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _openingUserId = null);
    }
  }

  Future<_ConversationPreview> _obtenerOCrearConversacion(
    ApiUser contact,
  ) async {
    final created = await _conversacionService.crearConversacion({
      'usuario1Id': _usuarioActualId,
      'usuario2Id': contact.id,
    });
    return _ConversationPreview.fromJson(created);
  }

  Widget _buildContactsList(List<ApiUser> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No se encontraron contactos.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        final isOpening = _openingUserId == user.id;
        final note = _noteForUser(user.id);
        return ListTile(
          minVerticalPadding: 12,
          leading: _AvatarWithNote(
            name: user.nombreMostrar,
            imageUrl: user.fotoPerfilUrl,
            note: note,
            showOnlineIndicator: user.estadoActivo,
          ),
          title: Text(
            user.nombreMostrar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: _ContactSubtitle(user: user, note: note),
          trailing: isOpening
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'Enviar mensaje',
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _openChat(user),
                ),
          onTap: () => _openChat(user),
        );
      },
    );
  }

  Widget _buildStoriesView() {
    if (_storiesLoading && _stories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_storiesError != null && _stories.isEmpty) {
      return _buildErrorState(
        _storiesError,
        'No se pudieron cargar las historias.',
        _loadStories,
      );
    }
    if (_stories.isEmpty) return _buildEmptyStoriesState();

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _stories.length + (_storiesError == null ? 0 : 1),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (_storiesError != null && index == 0) {
            return MaterialBanner(
              content: const Text(
                'Se muestran las historias cargadas. No se pudo actualizar.',
              ),
              actions: [
                TextButton(
                  onPressed: _loadStories,
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          final storyIndex = _storiesError == null ? index : index - 1;
          return _buildStoryTile(_stories[storyIndex]);
        },
      ),
    );
  }

  Widget _buildStoryTile(StoryModel story) {
    final colorScheme = Theme.of(context).colorScheme;
    final note = _noteForUser(story.usuarioId);
    final isDeleting = _deletingStoryId == story.id;
    return ListTile(
      minVerticalPadding: 12,
      leading: _AvatarWithNote(
        name: story.nombreMostrar,
        imageUrl: story.fotoPerfilUrl,
        note: note,
        showUnseenRing: !story.vista && !story.propia,
      ),
      title: Text(
        story.propia ? 'Tu historia' : story.nombreMostrar,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _StorySubtitle(
        timeText: _relativeTime(story.fechaPublicacion),
        note: note,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StoryThumbnail(imageUrl: story.imagenUrl),
          if (story.propia) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Eliminar estado',
              onPressed: isDeleting ? null : () => _confirmDeleteStory(story),
              icon: isDeleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.delete_outline, color: colorScheme.error),
            ),
          ],
        ],
      ),
      onTap: () => _openStory(story),
      iconColor: colorScheme.primary,
    );
  }

  Future<void> _confirmDeleteStory(StoryModel story) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar estado'),
        content: const Text('¿Quieres eliminar este estado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await _deleteStory(story);
  }

  Future<void> _deleteStory(StoryModel story) async {
    if (_deletingStoryId != null) return;
    setState(() => _deletingStoryId = story.id);
    try {
      await _historiaService.eliminarHistoria(story.id, _usuarioActualId);
      if (!mounted) return;
      setState(() {
        _stories = _stories
            .where((item) => item.id != story.id)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado eliminado.')));
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar el estado.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _deletingStoryId = null);
    }
  }

  NoteModel? _noteForUser(int usuarioId) {
    for (final note in _notes) {
      if (note.usuarioId == usuarioId) return note;
    }
    return null;
  }

  Future<void> _openStory(StoryModel story) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerScreen(story: story, usuarioActualId: _usuarioActualId),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      await _loadStories();
      return;
    }
    setState(() {
      _stories = _stories
          .map(
            (item) => item.id == story.id ? item.copyWith(vista: true) : item,
          )
          .toList(growable: false);
    });
  }

  Widget _buildEmptyStoriesState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay historias por ahora. Sube una foto para compartir tu estado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    Object? error,
    String fallback,
    VoidCallback onRetry,
  ) {
    final message = error is ApiException ? error.message : fallback;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Hace un momento';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AvatarWithNote extends StatelessWidget {
  const _AvatarWithNote({
    required this.name,
    required this.imageUrl,
    required this.note,
    this.showOnlineIndicator = false,
    this.showUnseenRing = false,
  });

  final String name;
  final String imageUrl;
  final NoteModel? note;
  final bool showOnlineIndicator;
  final bool showUnseenRing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ProfileAvatar(
            name: name,
            imageUrl: imageUrl,
            radius: 28,
            showOnlineIndicator: showOnlineIndicator,
            showUnseenRing: showUnseenRing,
          ),
          if (note != null)
            Positioned(
              top: -5,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 58),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  note!.contenido,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactSubtitle extends StatelessWidget {
  const _ContactSubtitle({required this.user, required this.note});

  final ApiUser user;
  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@${user.nombreUsuario}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          _NotePill(text: note!.contenido),
        ],
      ],
    );
  }
}

class _StorySubtitle extends StatelessWidget {
  const _StorySubtitle({required this.timeText, required this.note});

  final String timeText;
  final NoteModel? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeText),
        if (note != null) ...[
          const SizedBox(height: 4),
          _NotePill(text: note!.contenido),
        ],
      ],
    );
  }
}

class _NotePill extends StatelessWidget {
  const _NotePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StoryThumbnail extends StatelessWidget {
  const _StoryThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiService.resolveMediaUrl(imageUrl);
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 52,
        child: resolvedUrl.isEmpty
            ? ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ConversationPreview {
  final String id;
  final String nombreContacto;

  const _ConversationPreview({required this.id, required this.nombreContacto});

  factory _ConversationPreview.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La conversacion recibida no es valida.');
    }
    final map = Map<String, dynamic>.from(json);
    return _ConversationPreview(
      id: _requiredText(map['id'], 'id'),
      nombreContacto: map['nombreContacto']?.toString().trim() ?? '',
    );
  }

  bool matchesContact(ApiUser contact) =>
      nombreContacto.trim().toLowerCase() ==
      contact.nombreMostrar.trim().toLowerCase();

  static String _requiredText(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('La conversacion no tiene $fieldName.');
    }
    return text;
  }
}
