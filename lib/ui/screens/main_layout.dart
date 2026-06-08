import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_user.dart';
import '../../providers/session_provider.dart';
import '../../services/usuario_service.dart';
import 'chat_list.dart';
import 'people_list.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final UsuarioService _usuarioService = UsuarioService();
  int _currentIndex = 0;
  int _chatListReloadKey = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialUser());
  }

  @override
  void dispose() {
    _usuarioService.close();
    super.dispose();
  }

  Future<void> _loadInitialUser() async {
    try {
      final session = context.read<SessionProvider>();
      final response = await _usuarioService.obtenerUsuario(
        session.usuarioActualId,
      );
      if (mounted) session.sincronizarUsuario(ApiUser.fromJson(response));
    } catch (_) {
      // Cada pantalla mantiene su propio estado de error para la API.
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActualId = context.watch<SessionProvider>().usuarioActualId;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _visitedTabs.contains(0)
              ? ChatListScreen(
                  key: ValueKey('chats-$usuarioActualId-$_chatListReloadKey'),
                )
              : const SizedBox.shrink(),
          _visitedTabs.contains(1)
              ? PeopleListScreen(key: ValueKey('personas-$usuarioActualId'))
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? SettingsScreen(key: ValueKey('ajustes-$usuarioActualId'))
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
            if (index == 0) _chatListReloadKey++;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Personas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
