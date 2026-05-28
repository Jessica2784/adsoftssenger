import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../models/user_model.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  User? _selectedUser;
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _createChat() {
    if (_selectedUser == null) return;

    DummyData.createChatWith(
      contact: _selectedUser!,
      text: _msgController.text.trim(),
      time: TimeOfDay.now().format(context),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final users = DummyData.activeUsers;

    return AlertDialog(
      title: const Text('Nueva conversación'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<User>(
              initialValue: _selectedUser,
              isExpanded: true,
              items: users
                  .map(
                    (user) => DropdownMenuItem(
                      value: user,
                      child: Text(user.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (user) => setState(() => _selectedUser = user),
              decoration: const InputDecoration(
                labelText: 'Selecciona un usuario',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Primer mensaje (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedUser == null ? null : _createChat,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
