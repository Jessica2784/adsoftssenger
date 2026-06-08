import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/api_user.dart';
import '../../providers/session_provider.dart';
import '../../services/api_service.dart';
import '../../services/usuario_service.dart';
import '../../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  List<ApiUser> _users = [];
  Object? _error;
  bool _loading = true;
  int? _switchingId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usuarioService.close();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _usuarioService.obtenerUsuarios();
      final users = response.map(ApiUser.fromJson).toList()
        ..sort((a, b) => a.nombreMostrar.compareTo(b.nombreMostrar));
      if (!mounted) return;

      final session = context.read<SessionProvider>();
      for (final user in users) {
        if (user.id == session.usuarioActualId) {
          session.sincronizarUsuario(user);
          break;
        }
      }

      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _pickProfile() async {
    if (_loading || _users.isEmpty) {
      await _loadUsers();
      if (!mounted || _users.isEmpty) return;
    }

    final currentId = context.read<SessionProvider>().usuarioActualId;
    final selected = await showDialog<ApiUser>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar perfil'),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isCurrent = user.id == currentId;
                return ListTile(
                  leading: ProfileAvatar(
                    name: user.nombreMostrar,
                    imageUrl: user.fotoPerfilUrl,
                    radius: 22,
                  ),
                  title: Text(user.nombreMostrar),
                  subtitle: Text(
                    isCurrent
                        ? 'Perfil activo'
                        : user.predeterminado
                        ? 'Acceso directo'
                        : 'Requiere contraseña',
                  ),
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: isCurrent
                      ? null
                      : () => Navigator.pop(dialogContext, user),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;
    await _switchProfile(selected);
  }

  Future<void> _switchProfile(ApiUser selected) async {
    if (selected.predeterminado) {
      context.read<SessionProvider>().usarUsuario(selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil activo: ${selected.nombreMostrar}')),
      );
      return;
    }

    final enteredPassword = await _askPassword(selected.nombreMostrar);
    if (enteredPassword == null || !mounted) return;

    setState(() => _switchingId = selected.id);
    try {
      final authenticatedUser = await _validarUsuarioManual(
        selected,
        enteredPassword,
      );
      if (!mounted) return;
      context.read<SessionProvider>().usarUsuario(authenticatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil activo: ${authenticatedUser.nombreMostrar}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo cambiar de perfil.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _switchingId = null);
    }
  }

  Future<ApiUser> _validarUsuarioManual(
    ApiUser selected,
    String password,
  ) async {
    try {
      final response = await _usuarioService.validarCambioPerfil(
        selected.id,
        password,
      );
      return ApiUser.fromJson(response);
    } on ApiException catch (error) {
      if (error.statusCode != 404 || selected.correo.isEmpty) rethrow;
      final response = await _usuarioService.login({
        'correo': selected.correo,
        'password': password,
      });
      return ApiUser.fromJson(response);
    }
  }

  Future<String?> _askPassword(String name) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contraseña de $name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) Navigator.pop(dialogContext, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = context.watch<SessionProvider>();
    final user = session.usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar perfiles',
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _loading && user == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: ProfileAvatar(
                        name: user?.nombreMostrar ?? 'Jessica',
                        imageUrl: user?.fotoPerfilUrl ?? '',
                        radius: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            user?.nombreMostrar ?? 'Jessica',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user != null)
                            Text(
                              '@${user.nombreUsuario}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _error is ApiException
                              ? (_error! as ApiException).message
                              : 'No se pudieron cargar los perfiles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ListTile(
                      leading: Icon(
                        Icons.switch_account,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Cambiar perfil'),
                      subtitle: Text(
                        'Perfil actual: ${user?.nombreMostrar ?? 'Jessica'}',
                      ),
                      trailing: _switchingId == null
                          ? const Icon(Icons.chevron_right)
                          : const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                      onTap: _switchingId == null ? _pickProfile : null,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.photo_camera_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Foto de perfil'),
                      subtitle: const Text('Subir foto al servidor'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: user == null
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                              if (mounted) await _loadUsers();
                            },
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => SwitchListTile(
                        secondary: Icon(
                          Icons.brightness_6,
                          color: colorScheme.primary,
                        ),
                        title: const Text('Modo oscuro'),
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: themeProvider.toggleTheme,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
