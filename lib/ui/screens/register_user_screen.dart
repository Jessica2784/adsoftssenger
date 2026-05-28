import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/dummy_data.dart';
import '../../models/user_model.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _imageBytes = bytes;
    });
  }

  void _registerUser() {
    if (!_formKey.currentState!.validate()) return;

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      profileUrl: 'https://i.pravatar.cc/150?img=3',
      avatarBytes: _imageBytes,
    );

    DummyData.addProfile(newUser);
    Navigator.pop(context);
  }

  ImageProvider get _avatarProvider {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    return const NetworkImage('https://i.pravatar.cc/150?img=3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar usuario')),
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundImage: _avatarProvider,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: IconButton.filled(
                              icon: const Icon(Icons.camera_alt),
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _registerUser,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Registrar'),
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
