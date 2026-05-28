import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dummy_data.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickProfile() async {
    final selectedUser = await showDialog<User>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Cambiar perfil'),
          content: SizedBox(
            width: 420,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: DummyData.profiles.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: colorScheme.outlineVariant),
                itemBuilder: (context, index) {
                  final user = DummyData.profiles[index];
                  final isCurrent = user.id == DummyData.currentUser.id;

                  return ListTile(
                    leading: UserAvatar(
                      user: user,
                      radius: 22,
                      showOnlineIndicator: false,
                    ),
                    title: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      isCurrent ? 'Perfil activo' : 'Cambiar a este perfil',
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(context, user),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selectedUser == null || selectedUser.id == DummyData.currentUser.id) {
      return;
    }

    setState(() {
      DummyData.switchProfile(selectedUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 24),
              Center(
                child: UserAvatar(user: DummyData.currentUser, radius: 48),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      DummyData.currentUser.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (DummyData.currentUser.description != null &&
                        DummyData.currentUser.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DummyData.currentUser.description!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.switch_account, color: colorScheme.primary),
                title: const Text('Cambiar perfil'),
                subtitle: Text('Perfil actual: ${DummyData.currentUser.name}'),
                onTap: _pickProfile,
              ),
              ListTile(
                leading: Icon(Icons.edit, color: colorScheme.primary),
                title: const Text('Editar perfil'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                  if (mounted) setState(() {});
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
              ListTile(
                leading: Icon(Icons.lock, color: colorScheme.primary),
                title: const Text('Privacidad'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: colorScheme.primary),
                title: const Text('Notificaciones'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.info, color: colorScheme.primary),
                title: const Text('Acerca de'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
