import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? body;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const String baseUrl =
      'https://adsoftssenger-backend.onrender.com/api';
  static const Duration timeout = Duration(seconds: 45);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static String resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) return trimmed;

    final apiUri = Uri.parse(baseUrl);
    final origin = Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    );
    return origin.resolve(trimmed).toString();
  }

  Future<Map<String, dynamic>> getMap(String endpoint) async {
    final uri = _uri(endpoint);
    final response = await _send(
      'GET',
      uri,
      _client.get(uri, headers: _headers),
    );
    return _decodeMapResponse(response);
  }

  Future<Map<String, dynamic>> postMap(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(endpoint);
    final response = await _send(
      'POST',
      uri,
      _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );
    return _decodeMapResponse(response);
  }

  Future<Map<String, dynamic>> putMap(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(endpoint);
    final response = await _send(
      'PUT',
      uri,
      _client.put(uri, headers: _headers, body: jsonEncode(body)),
    );
    return _decodeMapResponse(response);
  }

  Future<Map<String, dynamic>> postMultipartMap(
    String endpoint, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    return _multipartMap(
      'POST',
      endpoint,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<Map<String, dynamic>> putMultipartMap(
    String endpoint, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    return _multipartMap(
      'PUT',
      endpoint,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<Map<String, dynamic>> _multipartMap(
    String method,
    String endpoint, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final uri = _uri(endpoint);
    final request = http.MultipartRequest(method, uri)
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          bytes,
          filename: filename,
          contentType: _parseMediaType(contentType),
        ),
      );

    final response = await _sendStreamed(method, uri, request.send());
    return _decodeMapResponse(response);
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final uri = _uri(endpoint);
    final response = await _send(
      'GET',
      uri,
      _client.get(uri, headers: _headers),
    );
    return _decodeListResponse(response);
  }

  Future<void> delete(String endpoint) async {
    final uri = _uri(endpoint);
    final response = await _send(
      'DELETE',
      uri,
      _client.delete(uri, headers: _headers),
    );
    _decodeSuccessfulJson(response);
  }

  void close() {
    _client.close();
  }

  Uri _uri(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    return Uri.parse('$baseUrl$normalizedEndpoint');
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Future<http.Response> request,
  ) async {
    foundation.debugPrint('API $method $uri');

    try {
      final response = await request.timeout(timeout);
      _logResponse(method, uri, response);
      return response;
    } on TimeoutException {
      foundation.debugPrint('API timeout [$method $uri]');
      throw const ApiException(
        statusCode: 0,
        message:
            'El servidor está iniciando, intenta de nuevo en unos segundos.',
      );
    } on http.ClientException catch (error) {
      foundation.debugPrint(
        'API connection error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor.',
      );
    } on Exception catch (error) {
      foundation.debugPrint('API unexpected error [$method $uri]: $error');
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor.',
      );
    }
  }

  Future<http.Response> _sendStreamed(
    String method,
    Uri uri,
    Future<http.StreamedResponse> request,
  ) async {
    foundation.debugPrint('API $method $uri');

    try {
      final streamed = await request.timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      _logResponse(method, uri, response);
      return response;
    } on TimeoutException {
      foundation.debugPrint('API timeout [$method $uri]');
      throw const ApiException(
        statusCode: 0,
        message:
            'El servidor está iniciando, intenta de nuevo en unos segundos.',
      );
    } on http.ClientException catch (error) {
      foundation.debugPrint(
        'API connection error [$method $uri]: ${error.message}',
      );
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor.',
      );
    } on Exception catch (error) {
      foundation.debugPrint('API unexpected error [$method $uri]: $error');
      throw const ApiException(
        statusCode: 0,
        message: 'No se pudo conectar con el servidor.',
      );
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    foundation.debugPrint(
      'API statusCode [$method $uri]: ${response.statusCode}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      foundation.debugPrint('API error body [$method $uri]: ${response.body}');
    }
  }

  MediaType _parseMediaType(String value) {
    try {
      return MediaType.parse(value);
    } on FormatException {
      return MediaType('image', 'jpeg');
    }
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
      return 'La solicitud tiene datos invalidos. Revisa la informacion e intenta de nuevo.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Credenciales incorrectas o acceso no autorizado.';
    }
    if (statusCode == 404) {
      return 'Esta función no está disponible en el servidor. Despliega el backend actualizado en Render e intenta de nuevo.';
    }
    if (statusCode >= 500) {
      return 'El servidor está iniciando, intenta de nuevo en unos segundos.';
    }

    return 'No se pudo completar la solicitud. Intenta de nuevo.';
  }

  String? _bodyMessage(Object? body) {
    if (body is Map) {
      for (final key in ['message', 'mensaje', 'error', 'detail']) {
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
}
