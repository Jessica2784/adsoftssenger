import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final MediaService _mediaService = MediaService();
  Uint8List? _localPreviewBytes;
  bool _saving = false;

  @override
  void dispose() {
    _mediaService.close();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_saving) return;
    final picked = await pickImageFromCameraOrGallery(
      context,
      picker: _imagePicker,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _localPreviewBytes = bytes);

      final session = context.read<SessionProvider>();
      final fotoPerfilUrl = await _mediaService.uploadProfilePhoto(
        session.usuarioActualId,
        File(picked.path),
      );
      if (!mounted) return;

      final currentUser = context.read<SessionProvider>().usuarioActual;
      if (currentUser != null) {
        context.read<SessionProvider>().sincronizarUsuario(
          currentUser.copyWith(fotoPerfilUrl: fotoPerfilUrl),
        );
      }

      setState(() => _localPreviewBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _localPreviewBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la foto. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearLocalPreview() {
    setState(() => _localPreviewBytes = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vista previa local eliminada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().usuarioActual;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Foto de perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: _buildAvatar(user?.nombreMostrar ?? 'Usuario')),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _localPreviewBytes == null
                      ? 'Elegir foto del celular'
                      : 'Subiendo foto...',
                ),
              ),
              if (_localPreviewBytes != null && !_saving) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _clearLocalPreview,
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  label: Text(
                    'Quitar vista previa',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
              if (_saving) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final bytes = _localPreviewBytes;
    if (bytes == null) {
      final user = context.watch<SessionProvider>().usuarioActual;
      return ProfileAvatar(
        name: name,
        imageUrl: user?.fotoPerfilUrl ?? '',
        radius: 72,
      );
    }

    return CircleAvatar(radius: 72, backgroundImage: MemoryImage(bytes));
  }
}
