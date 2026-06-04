import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/conversacion_service.dart';
import '../../services/usuario_service.dart';
import 'chat_detail.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  static const int _usuarioActualId = 1;

  final TextEditingController _searchController = TextEditingController();
  final UsuarioService _usuarioService = UsuarioService();
  final ConversacionService _conversacionService = ConversacionService();

  List<_ApiUser> _users = [];
  Object? _loadError;
  int _selectedView = 0;
  int? _openingUserId;
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usuarioService.close();
    _conversacionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                    setState(() => _selectedView = selection.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildCurrentView(context, contacts, colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadUsers,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    );
  }

  List<_ApiUser> get _contactUsers {
    return _users
        .where((user) => user.id != _usuarioActualId)
        .toList(growable: false);
  }

  _ApiUser? get _currentUser {
    for (final user in _users) {
      if (user.id == _usuarioActualId) return user;
    }
    return null;
  }

  Widget _buildCurrentView(
    BuildContext context,
    List<_ApiUser> contacts,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(
        key: ValueKey('people-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return _buildErrorState(context);
    }

    return _selectedView == 0
        ? _buildContactsList(context, contacts)
        : _buildStoriesList(context, contacts, colorScheme);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await _usuarioService.obtenerUsuarios();
      final users = response.map(_ApiUser.fromJson).toList(growable: false)
        ..sort((a, b) => a.nombreMostrar.compareTo(b.nombreMostrar));

      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  List<_ApiUser> _filterUsers(List<_ApiUser> users, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return users;

    return users
        .where((user) {
          final searchableText = [
            user.nombreMostrar,
            user.nombreUsuario,
          ].join(' ').toLowerCase();
          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<void> _openChat(_ApiUser contact) async {
    if (_openingUserId != null) return;

    setState(() {
      _openingUserId = contact.id;
    });

    try {
      final conversation = await _obtenerOCrearConversacion(contact);
      if (!mounted) return;

      setState(() {
        _openingUserId = null;
      });

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
      if (mounted && _openingUserId == contact.id) {
        setState(() {
          _openingUserId = null;
        });
      }
    }
  }

  Future<_ConversationPreview> _obtenerOCrearConversacion(
    _ApiUser contact,
  ) async {
    final conversaciones = await _conversacionService
        .obtenerConversacionesPorUsuario(_usuarioActualId);

    for (final item in conversaciones) {
      final conversation = _ConversationPreview.fromJson(item);
      if (conversation.matchesContact(contact)) {
        return conversation;
      }
    }

    final created = await _conversacionService.crearConversacion({
      'usuario1Id': _usuarioActualId,
      'usuario2Id': contact.id,
    });

    return _ConversationPreview.fromJson(created);
  }

  Widget _buildContactsList(BuildContext context, List<_ApiUser> users) {
    final colorScheme = Theme.of(context).colorScheme;

    if (users.isEmpty) {
      return Center(
        key: const ValueKey('contacts-empty'),
        child: Text(
          'No se encontraron contactos.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('contacts'),
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: users.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        final isOpening = _openingUserId == user.id;

        return ListTile(
          minVerticalPadding: 12,
          leading: _PersonAvatar(user: user, radius: 28),
          title: Text(
            user.nombreMostrar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '@${user.nombreUsuario}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.estadoActivo) ...[
                const SizedBox(width: 8),
                Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Activo',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          trailing: isOpening
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'Enviar mensaje',
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => _openChat(user),
                ),
          onTap: () => _openChat(user),
        );
      },
    );
  }

  Widget _buildStoriesList(
    BuildContext context,
    List<_ApiUser> users,
    ColorScheme colorScheme,
  ) {
    final currentUser = _currentUser;

    return ListView(
      key: const ValueKey('stories'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      children: [
        if (currentUser != null)
          _StoryTile(
            user: currentUser,
            title: 'Tu estado',
            subtitle: currentUser.estadoActivo
                ? 'Perfil activo'
                : 'Sin actividad reciente',
            trailing: IconButton.filledTonal(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
            ),
            onTap: _loadUsers,
          ),
        if (currentUser != null) const SizedBox(height: 8),
        for (final user in users.take(6))
          _StoryTile(
            user: user,
            title: user.nombreMostrar,
            subtitle: user.estadoActivo ? 'Activo' : 'Sin actividad reciente',
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _openChat(user),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = _loadError is ApiException
        ? (_loadError! as ApiException).message
        : 'No se pudieron cargar las personas.';

    return Center(
      key: const ValueKey('people-error'),
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
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiUser {
  final int id;
  final String nombreUsuario;
  final String nombreMostrar;
  final String fotoPerfilUrl;
  final bool estadoActivo;

  const _ApiUser({
    required this.id,
    required this.nombreUsuario,
    required this.nombreMostrar,
    required this.fotoPerfilUrl,
    required this.estadoActivo,
  });

  factory _ApiUser.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('El usuario recibido no es valido.');
    }

    final map = Map<String, dynamic>.from(json);

    return _ApiUser(
      id: _intValue(map['id']),
      nombreUsuario: _text(map['nombreUsuario'], fallback: 'usuario'),
      nombreMostrar: _text(map['nombreMostrar'], fallback: 'Usuario'),
      fotoPerfilUrl: _text(map['fotoPerfilUrl']),
      estadoActivo: _boolValue(map['estadoActivo']),
    );
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}

class _ConversationPreview {
  final String id;
  final String nombreContacto;
  final String fotoContactoUrl;

  const _ConversationPreview({
    required this.id,
    required this.nombreContacto,
    required this.fotoContactoUrl,
  });

  factory _ConversationPreview.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La conversacion recibida no es valida.');
    }

    final map = Map<String, dynamic>.from(json);

    return _ConversationPreview(
      id: _requiredText(map['id'], 'id'),
      nombreContacto: _text(map['nombreContacto']),
      fotoContactoUrl: _text(map['fotoContactoUrl']),
    );
  }

  bool matchesContact(_ApiUser contact) {
    return _normalize(nombreContacto) == _normalize(contact.nombreMostrar);
  }

  static String _requiredText(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('La conversacion no tiene $fieldName.');
    }
    return text;
  }

  static String _text(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.user, required this.radius});

  final _ApiUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(child: _buildImage(context)),
    );

    if (!user.estadoActivo) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.35,
            height: radius * 0.35,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = user.fotoPerfilUrl.trim();
    if (imageUrl.isEmpty) return _fallback(context);

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = user.nombreMostrar
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

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.user,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final _ApiUser user;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        minVerticalPadding: 12,
        leading: _PersonAvatar(user: user, radius: 28),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
