import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' as foundation;
import 'package:http/http.dart' as http;

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
  static const String baseUrl = 'http://localhost:8080/api';
  static const Duration timeout = Duration(seconds: 15);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> postMap(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri(endpoint);
    final response = await _send(
      uri,
      _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );

    return _decodeMapResponse(response);
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final uri = _uri(endpoint);
    final response = await _send(uri, _client.get(uri, headers: _headers));

    return _decodeListResponse(response);
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

  Future<http.Response> _send(Uri uri, Future<http.Response> request) async {
    foundation.debugPrint('API URL consultada: $uri');

    try {
      final response = await request.timeout(timeout);
      foundation.debugPrint('API statusCode: ${response.statusCode}');
      foundation.debugPrint('API body: ${response.body}');
      return response;
    } on TimeoutException {
      foundation.debugPrint('API error: timeout consultando $uri');
      throw const ApiException(
        statusCode: 0,
        message: 'Tiempo de espera agotado al conectar con la API.',
      );
    } on http.ClientException catch (error) {
      foundation.debugPrint('API error consultando $uri: ${error.message}');
      throw ApiException(statusCode: 0, message: error.message);
    }
  }

  Map<String, dynamic> _decodeMapResponse(http.Response response) {
    final decodedBody = _decodeSuccessfulJson(response);

    if (decodedBody == null) {
      return <String, dynamic>{};
    }

    if (decodedBody is Map) {
      return Map<String, dynamic>.from(decodedBody);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'Se esperaba un objeto JSON en la respuesta.',
      body: decodedBody,
    );
  }

  List<dynamic> _decodeListResponse(http.Response response) {
    final decodedBody = _decodeSuccessfulJson(response);

    if (decodedBody == null) {
      return <dynamic>[];
    }

    if (decodedBody is List) {
      return List<dynamic>.from(decodedBody);
    }

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
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final body = utf8.decode(response.bodyBytes);

    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _errorMessage(int statusCode, Object? body) {
    if (body is Map) {
      for (final key in ['message', 'mensaje', 'error', 'detail']) {
        final value = body[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    return 'Error $statusCode al consumir la API.';
  }
}
