import 'dart:typed_data';

import 'api_service.dart';

class MensajeService {
  final ApiService _apiService;

  MensajeService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> enviarMensaje(Map<String, dynamic> mensaje) {
    return _apiService.postMap('/mensajes', mensaje);
  }

  Future<Map<String, dynamic>> enviarImagen({
    required Object conversacionId,
    required Object remitenteId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    final conversation = Uri.encodeComponent(conversacionId.toString());
    final sender = Uri.encodeComponent(remitenteId.toString());
    return _apiService.postMultipartMap(
      '/mensajes/imagen?conversacionId=$conversation&remitenteId=$sender',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<List<dynamic>> obtenerMensajesPorConversacion(Object conversacionId) {
    final encodedConversacionId = Uri.encodeComponent(
      conversacionId.toString(),
    );
    return _apiService.getList('/mensajes/conversacion/$encodedConversacionId');
  }

  Future<void> eliminarMensaje(Object mensajeId) {
    final encodedMensajeId = Uri.encodeComponent(mensajeId.toString());
    return _apiService.delete('/mensajes/$encodedMensajeId');
  }

  void close() {
    _apiService.close();
  }
}
