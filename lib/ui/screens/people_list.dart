import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/dummy_data.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import 'chat_detail.dart';
import 'register_user_screen.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  int _selectedView = 0;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final users = DummyData.activeUsers;
    final visibleUsers = _filterUsers(users, _searchController.text);

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
                  child: _selectedView == 0
                      ? _buildContactsList(context, visibleUsers)
                      : _buildStoriesList(context, visibleUsers, colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedView == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar'),
            )
          : FloatingActionButton.extended(
              onPressed: _showStatusComposer,
              icon: const Icon(Icons.add_circle),
              label: const Text('Nuevo estado'),
            ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  List<User> _filterUsers(List<User> users, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return users;

    return users
        .where((user) {
          final searchableText = [
            user.name,
            user.description ?? '',
            for (final status in user.statuses) status.note,
          ].join(' ').toLowerCase();
          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<void> _openChat(User contact) async {
    final chat =
        DummyData.findChatWith(contact.id) ??
        DummyData.createChatWith(
          contact: contact,
          text: '',
          time: TimeOfDay.now().format(context),
        );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(contact: contact, chatId: chat.id),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _showStatusComposer() async {
    final controller = TextEditingController();
    Uint8List? imageBytes;
    String? imageName;

    final status = await showDialog<ProfileStatus>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickStatusImage(ImageSource source) async {
            try {
              final pickedImage = await _imagePicker.pickImage(
                source: source,
                imageQuality: 86,
                maxWidth: 1600,
              );
              if (pickedImage == null) return;

              final bytes = await pickedImage.readAsBytes();
              if (!context.mounted) return;

              setDialogState(() {
                imageBytes = bytes;
                imageName = pickedImage.name;
              });
            } catch (_) {
              if (!mounted) return;
              final sourceName = source == ImageSource.camera
                  ? 'la camara'
                  : 'la galeria';
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No se pudo abrir $sourceName. Revisa los permisos del dispositivo.',
                  ),
                ),
              );
            }
          }

          final hasContent =
              controller.text.trim().isNotEmpty ||
              (imageBytes != null && imageBytes!.isNotEmpty);

          return AlertDialog(
            title: const Text('Nuevo estado'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 80,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota o estado',
                      hintText: '¿Que estas haciendo?',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => pickStatusImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camara'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => pickStatusImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text('Galeria'),
                      ),
                      if (imageBytes != null)
                        IconButton.filledTonal(
                          tooltip: 'Quitar foto',
                          onPressed: () {
                            setDialogState(() {
                              imageBytes = null;
                              imageName = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: hasContent
                    ? () => Navigator.pop(
                        dialogContext,
                        ProfileStatus(
                          note: controller.text.trim(),
                          imageBytes: imageBytes,
                          imageName: imageName,
                        ),
                      )
                    : null,
                child: const Text('Publicar'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();

    if (!mounted || status == null) return;
    setState(() {
      DummyData.currentUser.addStatus(status);
    });
  }

  Future<void> _showStatusViewer(User user) async {
    final statuses = user.statuses
        .where((status) => !status.isEmpty)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    if (statuses.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          user: user,
                          radius: 22,
                          showStatusRing: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (user.id == DummyData.currentUser.id)
                          IconButton.filledTonal(
                            tooltip: 'Agregar estado',
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusComposer();
                            },
                            icon: const Icon(Icons.add),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: statuses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _StatusPreviewCard(status: statuses[index]),
                      ),
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

  Widget _buildContactsList(BuildContext context, List<User> users) {
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
        final User user = users[index];
        final statusPreview = user.statusPreview;
        return ListTile(
          minVerticalPadding: 12,
          leading: UserAvatar(user: user, radius: 28, showStatusRing: true),
          title: Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            statusPreview.isEmpty ? 'Perfil disponible' : statusPreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
          onTap: () => _openChat(user),
        );
      },
    );
  }

  Widget _buildStoriesList(
    BuildContext context,
    List<User> users,
    ColorScheme colorScheme,
  ) {
    final currentUser = DummyData.currentUser;

    return ListView(
      key: const ValueKey('stories'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      children: [
        _StoryTile(
          user: currentUser,
          title: 'Tu estado',
          subtitle: currentUser.hasStatuses
              ? _statusSubtitle(currentUser)
              : 'Agregar una actualizacion',
          trailing: IconButton.filledTonal(
            onPressed: _showStatusComposer,
            icon: const Icon(Icons.add),
          ),
          onTap: currentUser.hasStatuses
              ? () => _showStatusViewer(currentUser)
              : _showStatusComposer,
        ),
        const SizedBox(height: 8),
        for (final user in users.take(6))
          _StoryTile(
            user: user,
            title: user.name,
            subtitle: _statusSubtitle(user),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: user.hasStatuses ? () => _showStatusViewer(user) : null,
          ),
      ],
    );
  }

  String _statusSubtitle(User user) {
    if (!user.hasStatuses) return 'Estado reciente';
    final preview = user.statusPreview;
    if (user.statusCount == 1) return preview;
    return '${user.statusCount} estados · $preview';
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

  final User user;
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
        leading: UserAvatar(user: user, radius: 28, showStatusRing: true),
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

class _StatusPreviewCard extends StatelessWidget {
  const _StatusPreviewCard({required this.status});

  final ProfileStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  status.imageBytes!,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    alignment: Alignment.center,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (status.hasNote) const SizedBox(height: 10),
            ],
            if (status.hasNote)
              Text(
                status.note,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
          ],
        ),
      ),
    );
  }
}
