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

  void close() {
    _apiService.close();
  }
}
