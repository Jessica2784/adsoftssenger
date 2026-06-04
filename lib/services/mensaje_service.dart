import 'api_service.dart';

class MensajeService {
  final ApiService _apiService;

  MensajeService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> enviarMensaje(Map<String, dynamic> mensaje) {
    return _apiService.postMap('/mensajes', mensaje);
  }

  Future<List<dynamic>> obtenerMensajesPorConversacion(Object conversacionId) {
    final encodedConversacionId = Uri.encodeComponent(
      conversacionId.toString(),
    );
    return _apiService.getList('/mensajes/conversacion/$encodedConversacionId');
  }

  void close() {
    _apiService.close();
  }
}
