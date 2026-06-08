class ApiUser {
  static const Set<String> _usuariosPredeterminados = {
    'jessica',
    'adolfo',
    'carlos',
    'maria',
    'maría',
    'lucia',
    'lucía',
    'luis',
    'luis garcia',
    'luis garcía',
    'mateo',
    'mateo fernandez',
    'mateo fernández',
    'elena',
    'elena rodriguez',
    'elena rodríguez',
  };

  final int id;
  final String nombreUsuario;
  final String nombreMostrar;
  final String correo;
  final String fotoPerfilUrl;
  final bool estadoActivo;
  final bool predeterminado;

  const ApiUser({
    required this.id,
    required this.nombreUsuario,
    required this.nombreMostrar,
    required this.correo,
    required this.fotoPerfilUrl,
    required this.estadoActivo,
    required this.predeterminado,
  });

  factory ApiUser.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('El usuario recibido no es valido.');
    }

    final map = Map<String, dynamic>.from(json);
    final nombreUsuario = _text(map['nombreUsuario'], fallback: 'usuario');
    final nombreMostrar = _text(map['nombreMostrar'], fallback: 'Usuario');
    return ApiUser(
      id: _intValue(map['id']),
      nombreUsuario: nombreUsuario,
      nombreMostrar: nombreMostrar,
      correo: _text(map['correo']),
      fotoPerfilUrl: _text(map['fotoPerfilUrl']),
      estadoActivo: _boolValue(map['estadoActivo']),
      predeterminado:
          _boolValue(map['predeterminado']) ||
          _esUsuarioPredeterminado(nombreUsuario, nombreMostrar),
    );
  }

  ApiUser copyWith({
    int? id,
    String? nombreUsuario,
    String? nombreMostrar,
    String? correo,
    String? fotoPerfilUrl,
    bool? estadoActivo,
    bool? predeterminado,
  }) {
    return ApiUser(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombreMostrar: nombreMostrar ?? this.nombreMostrar,
      correo: correo ?? this.correo,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      estadoActivo: estadoActivo ?? this.estadoActivo,
      predeterminado: predeterminado ?? this.predeterminado,
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

  static bool _esUsuarioPredeterminado(
    String nombreUsuario,
    String nombreMostrar,
  ) {
    return _usuariosPredeterminados.contains(_normalizar(nombreUsuario)) ||
        _usuariosPredeterminados.contains(_normalizar(nombreMostrar));
  }

  static String _normalizar(String value) => value.trim().toLowerCase();
}
