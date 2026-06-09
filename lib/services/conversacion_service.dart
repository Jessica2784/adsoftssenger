import 'api_service.dart';

class ConversacionService {
  final ApiService _apiService;

  ConversacionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> crearConversacion(
    Map<String, dynamic> conversacion,
  ) {
    return _apiService.postMap('/conversaciones', conversacion);
  }

  Future<List<dynamic>> obtenerConversacionesPorUsuario(Object usuarioId) {
    final encodedUsuarioId = Uri.encodeComponent(usuarioId.toString());
    return _apiService.getList('/conversaciones/usuario/$encodedUsuarioId');
  }

  Future<Map<String, dynamic>> marcarComoLeida(
    Object conversacionId,
    Object usuarioId,
  ) {
    final encodedConversacionId = Uri.encodeComponent(
      conversacionId.toString(),
    );
    final encodedUsuarioId = Uri.encodeComponent(usuarioId.toString());
    return _apiService.putMap(
      '/conversaciones/$encodedConversacionId/leer/$encodedUsuarioId',
      {},
    );
  }

  void close() {
    _apiService.close();
  }
}
