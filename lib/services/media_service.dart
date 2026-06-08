// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;

import 'api_service.dart';

class MediaService {
  final http.Client _client;

  MediaService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> uploadProfilePhoto(int usuarioId, File imageFile) async {
    final response = await _uploadImage(
      '/media/profile-photo/$usuarioId',
      usuarioId,
      imageFile,
    );
    final fotoPerfilUrl = response['fotoPerfilUrl']?.toString().trim() ?? '';
    if (fotoPerfilUrl.isEmpty) {
      throw ApiException(
        statusCode: 0,
        message: 'No se pudo subir la foto. Intenta de nuevo.',
        body: response,
      );
    }
    return fotoPerfilUrl;
  }

  Future<Map<String, dynamic>> uploadStoryImage(int usuarioId, File imageFile) {
    return _uploadImage('/media/stories/$usuarioId', usuarioId, imageFile);
  }

  Future<List<dynamic>> getStories() async {
    final response = await _send(
      'GET',
      _uri('/stories'),
      _client.get(_uri('/stories')),
    );
    return _decodeListResponse(response);
  }

  Future<List<dynamic>> getStoriesByUser(int usuarioId) async {
    final endpoint = '/stories/usuario/$usuarioId';
    final response = await _send(
      'GET',
      _uri(endpoint),
      _client.get(_uri(endpoint)),
    );
    return _decodeListResponse(response);
  }

  Future<Map<String, dynamic>> _uploadImage(
    String endpoint,
    int usuarioId,
    File imageFile,
  ) async {
    final uri = _uri(endpoint);
    await _logUploadStart(uri, usuarioId, imageFile);

    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await _sendStreamed('POST', uri, request.send());
    return _decodeMapResponse(response);
  }

  Future<void> _logUploadStart(Uri uri, int usuarioId, File imageFile) async {
    print('=== SUBIENDO IMAGEN DESDE FLUTTER ===');
    print('URL: $uri');
    print('usuarioId: $usuarioId');
    print('path: ${imageFile.path}');
    final exists = await imageFile.exists();
    print('existe archivo: $exists');
    print('tamaño archivo: ${exists ? await imageFile.length() : 0}');
  }

  Uri _uri(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    return Uri.parse('${ApiService.baseUrl}$normalizedEndpoint');
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Future<http.Response> request,
  ) async {
    _logUrl(method, uri);
    try {
      final response = await request.timeout(ApiService.timeout);
      _logResponse(method, uri, response);
      return response;
    } on TimeoutException {
      foundation.debugPrint('MEDIA timeout [$method $uri]');
      throw const ApiException(
        statusCode: 0,
        message:
            'Tiempo de espera agotado. Revisa tu conexion e intenta de nuevo.',
      );
    } on SocketException catch (error) {
      foundation.debugPrint(
        'MEDIA connection error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    } on http.ClientException catch (error) {
      foundation.debugPrint(
        'MEDIA client error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    }
  }

  Future<http.Response> _sendStreamed(
    String method,
    Uri uri,
    Future<http.StreamedResponse> request,
  ) async {
    _logUrl(method, uri);
    try {
      final streamed = await request.timeout(ApiService.timeout);
      final response = await http.Response.fromStream(streamed);
      _logResponse(method, uri, response);
      return response;
    } on TimeoutException {
      foundation.debugPrint('MEDIA timeout [$method $uri]');
      throw const ApiException(
        statusCode: 0,
        message:
            'Tiempo de espera agotado. Revisa tu conexion e intenta de nuevo.',
      );
    } on SocketException catch (error) {
      foundation.debugPrint(
        'MEDIA connection error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    } on http.ClientException catch (error) {
      foundation.debugPrint(
        'MEDIA client error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    }
  }

  void _logUrl(String method, Uri uri) {
    foundation.debugPrint('MEDIA URL llamada [$method]: $uri');
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    final responseBody = response.body;
    foundation.debugPrint(
      'MEDIA statusCode [$method $uri]: ${response.statusCode}',
    );
    foundation.debugPrint('MEDIA body [$method $uri]: $responseBody');
    print('statusCode: ${response.statusCode}');
    print('body: $responseBody');
  }

  Map<String, dynamic> _decodeMapResponse(http.Response response) {
    final decodedBody = _decodeSuccessfulJson(response);
    if (decodedBody == null) return <String, dynamic>{};
    if (decodedBody is Map) return Map<String, dynamic>.from(decodedBody);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Se esperaba un objeto JSON en la respuesta.',
      body: decodedBody,
    );
  }

  List<dynamic> _decodeListResponse(http.Response response) {
    final decodedBody = _decodeSuccessfulJson(response);
    if (decodedBody == null) return <dynamic>[];
    if (decodedBody is List) return List<dynamic>.from(decodedBody);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Se esperaba una lista JSON en la respuesta.',
      body: decodedBody,
    );
  }

  Object? _decodeSuccessfulJson(http.Response response) {
    final decodedBody = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessage(response.statusCode, decodedBody),
        body: decodedBody,
      );
    }
    if (decodedBody is String) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'La respuesta de la API no es JSON valido.',
        body: decodedBody,
      );
    }
    return decodedBody;
  }

  Object? _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final body = utf8.decode(response.bodyBytes);
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _errorMessage(int statusCode, Object? body) {
    final bodyMessage = _bodyMessage(body);
    if (bodyMessage != null && !_isGenericServerMessage(bodyMessage)) {
      return bodyMessage;
    }
    if (statusCode == 400) {
      return 'La imagen o los datos enviados no son validos.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'No tienes permiso para realizar esta accion.';
    }
    if (statusCode == 404) {
      return 'No se encontro el recurso en el servidor. Actualiza la app o intenta de nuevo.';
    }
    if (statusCode >= 500) {
      return 'El servidor tuvo un problema al procesar la imagen. Intenta de nuevo.';
    }
    return 'No se pudo completar la solicitud. Intenta de nuevo.';
  }

  String? _bodyMessage(Object? body) {
    if (body is Map) {
      for (final key in ['detail', 'message', 'mensaje', 'error']) {
        final value = body[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    if (body is String && body.trim().isNotEmpty) return body.trim();
    return null;
  }

  bool _isGenericServerMessage(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized == 'not found' ||
        normalized == '404' ||
        normalized == '404 not found' ||
        normalized == 'bad request' ||
        normalized == 'unauthorized' ||
        normalized == 'forbidden' ||
        normalized == 'internal server error' ||
        normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html');
  }

  void close() => _client.close();
}
