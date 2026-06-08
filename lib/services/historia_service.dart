import 'dart:io';
import 'dart:typed_data';

import 'api_service.dart';
import 'media_service.dart';

class HistoriaNoDisponibleException implements Exception {
  final String message;

  const HistoriaNoDisponibleException(this.message);

  @override
  String toString() => message;
}

class HistoriaService {
  static const String unavailableMessage =
      'No hay historias disponibles por ahora.';

  final ApiService _apiService;
  final MediaService _mediaService;

  HistoriaService({ApiService? apiService, MediaService? mediaService})
    : _apiService = apiService ?? ApiService(),
      _mediaService = mediaService ?? MediaService();

  Future<List<dynamic>> obtenerHistorias(Object usuarioActualId) {
    return _mediaService.getStories();
  }

  Future<List<dynamic>> obtenerHistoriasPorUsuario(int usuarioId) {
    return _mediaService.getStoriesByUser(usuarioId);
  }

  Future<Map<String, dynamic>> crearHistoria({
    required Object usuarioId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final parsedUsuarioId = int.tryParse(usuarioId.toString());
    if (parsedUsuarioId == null || parsedUsuarioId <= 0) {
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo identificar el usuario para subir la historia.',
      );
    }

    final tempDirectory = await Directory.systemTemp.createTemp(
      'adsoftssenger_story_',
    );
    final tempFile = File(
      '${tempDirectory.path}/historia${_extensionFor(filename, contentType)}',
    );

    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      return _mediaService.uploadStoryImage(parsedUsuarioId, tempFile);
    } finally {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    }
  }

  Future<Map<String, dynamic>> marcarVista(
    Object historiaId,
    Object usuarioId,
  ) {
    return _apiService.postMap('/historias/$historiaId/vistas/$usuarioId', {});
  }

  Future<void> eliminarHistoria(Object historiaId, Object usuarioId) {
    return _apiService.delete('/historias/$historiaId?usuarioId=$usuarioId');
  }

  String _extensionFor(String filename, String contentType) {
    final lowerFilename = filename.toLowerCase();
    final lowerContentType = contentType.toLowerCase();
    if (lowerFilename.endsWith('.png') || lowerContentType.contains('png')) {
      return '.png';
    }
    if (lowerFilename.endsWith('.webp') || lowerContentType.contains('webp')) {
      return '.webp';
    }
    return '.jpg';
  }

  void close() {
    _apiService.close();
    _mediaService.close();
  }
}
