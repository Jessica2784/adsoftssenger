import 'package:flutter/foundation.dart';

import '../models/api_user.dart';

class SessionProvider extends ChangeNotifier {
  int _usuarioActualId = 1;
  ApiUser? _usuarioActual;

  int get usuarioActualId => _usuarioActualId;
  ApiUser? get usuarioActual => _usuarioActual;

  void usarUsuario(ApiUser usuario) {
    _usuarioActualId = usuario.id;
    _usuarioActual = usuario;
    notifyListeners();
  }

  void sincronizarUsuario(ApiUser usuario) {
    if (usuario.id != _usuarioActualId) return;
    _usuarioActual = usuario;
    notifyListeners();
  }
}
