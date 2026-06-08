class StoryModel {
  final int id;
  final int usuarioId;
  final String nombreMostrar;
  final String fotoPerfilUrl;
  final String imagenUrl;
  final DateTime? fechaPublicacion;
  final bool vista;
  final bool propia;

  const StoryModel({
    required this.id,
    required this.usuarioId,
    required this.nombreMostrar,
    required this.fotoPerfilUrl,
    required this.imagenUrl,
    required this.fechaPublicacion,
    required this.vista,
    required this.propia,
  });

  factory StoryModel.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La historia recibida no es valida.');
    }
    final map = Map<String, dynamic>.from(json);
    return StoryModel(
      id: _intValue(map['id']),
      usuarioId: _intValue(map['usuarioId']),
      nombreMostrar: _text(
        map['nombreMostrar'],
        fallback: _text(map['usuarioNombre'], fallback: 'Usuario'),
      ),
      fotoPerfilUrl: _text(map['fotoPerfilUrl']),
      imagenUrl: _text(map['imagenUrl']),
      fechaPublicacion: DateTime.tryParse(
        _text(map['fechaPublicacion'], fallback: _text(map['fechaCreacion'])),
      )?.toLocal(),
      vista: _boolValue(map['vista']),
      propia: _boolValue(map['propia']),
    );
  }

  StoryModel copyWith({bool? vista, bool? propia}) => StoryModel(
    id: id,
    usuarioId: usuarioId,
    nombreMostrar: nombreMostrar,
    fotoPerfilUrl: fotoPerfilUrl,
    imagenUrl: imagenUrl,
    fechaPublicacion: fechaPublicacion,
    vista: vista ?? this.vista,
    propia: propia ?? this.propia,
  );

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
}
