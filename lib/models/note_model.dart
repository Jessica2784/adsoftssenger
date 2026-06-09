class NoteModel {
  final String id;
  final int usuarioId;
  final String nombreMostrar;
  final String nombreUsuario;
  final String fotoPerfilUrl;
  final String contenido;
  final DateTime? fechaCreacion;

  const NoteModel({
    required this.id,
    required this.usuarioId,
    required this.nombreMostrar,
    required this.nombreUsuario,
    required this.fotoPerfilUrl,
    required this.contenido,
    required this.fechaCreacion,
  });

  factory NoteModel.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La nota recibida no es valida.');
    }
    final map = Map<String, dynamic>.from(json);
    final rawDate = _text(map['fechaCreacion']);
    return NoteModel(
      id: _text(map['id'], fallback: '0'),
      usuarioId: int.tryParse(_text(map['usuarioId'])) ?? 0,
      nombreMostrar: _text(map['nombreMostrar'], fallback: 'Usuario'),
      nombreUsuario: _text(map['nombreUsuario']),
      fotoPerfilUrl: _text(map['fotoPerfilUrl']),
      contenido: _text(map['contenido']),
      fechaCreacion: DateTime.tryParse(rawDate)?.toLocal(),
    );
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
