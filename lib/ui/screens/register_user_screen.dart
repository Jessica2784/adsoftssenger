import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/media_service.dart';
import '../../services/usuario_service.dart';
import '../../widgets/image_source_sheet.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UsuarioService _usuarioService = UsuarioService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nombreMostrarController =
      TextEditingController();
  final TextEditingController _nombreUsuarioController =
      TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  XFile? _profileImage;
  Uint8List? _profileBytes;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreMostrarController.dispose();
    _nombreUsuarioController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _usuarioService.close();
    _mediaService.close();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (_isSubmitting) return;
    final image = await pickImageFromCameraOrGallery(
      context,
      picker: _imagePicker,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _profileImage = image;
      _profileBytes = bytes;
    });
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final createdUser = await _usuarioService.registrarUsuario({
        'nombreUsuario': _nombreUsuarioController.text.trim(),
        'nombreMostrar': _nombreMostrarController.text.trim(),
        'correo': _correoController.text.trim(),
        'password': _passwordController.text,
      });

      final createdUserId = _intValue(createdUser['id']);
      if (_profileImage != null) {
        await _uploadSelectedPhoto(createdUserId);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo crear el usuario.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadSelectedPhoto(int usuarioId) async {
    final image = _profileImage;
    if (image == null) return;

    if (usuarioId <= 0) {
      _showPhotoUploadError();
      return;
    }

    try {
      await _mediaService.uploadProfilePhoto(usuarioId, File(image.path));
    } catch (_) {
      if (mounted) _showPhotoUploadError();
    }
  }

  void _showPhotoUploadError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo subir la foto. Intenta de nuevo.'),
      ),
    );
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _requiredValidator(value, 'El correo');
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingrese un correo valido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar usuario')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Tooltip(
                        message: 'Agregar foto de perfil',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isSubmitting ? null : _pickProfileImage,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: _profileBytes == null
                                    ? null
                                    : MemoryImage(_profileBytes!),
                                child: _profileBytes == null
                                    ? Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _pickProfileImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        _profileBytes == null
                            ? 'Agregar foto de perfil'
                            : 'Cambiar foto seleccionada',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreMostrarController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre para mostrar',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          _requiredValidator(value, 'El nombre para mostrar'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreUsuarioController,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) =>
                          _requiredValidator(value, 'El nombre de usuario'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          _requiredValidator(value, 'La contraseña'),
                      onFieldSubmitted: (_) => _registerUser(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _registerUser,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(
                        _isSubmitting
                            ? _profileImage == null
                                  ? 'Creando usuario...'
                                  : 'Creando y subiendo foto...'
                            : 'Crear usuario',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
