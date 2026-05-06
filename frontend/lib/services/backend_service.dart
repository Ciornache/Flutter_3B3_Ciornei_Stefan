import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BackendService {
  static String get _baseUrl => dotenv.env['BACKEND_BASE_URL']!;

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  static dynamic _decode(http.Response resp, String errorMessage) {
    if (resp.statusCode != 200) {
      throw Exception('$errorMessage (${resp.statusCode}): ${resp.body}');
    }
    if (resp.body.isEmpty) return null;
    return jsonDecode(resp.body);
  }

  static Map<String, String>? _jsonHeaders(Object? body) =>
      body == null ? null : const {'Content-Type': 'application/json'};

  static String? _encodeBody(Object? body) =>
      body == null ? null : jsonEncode(body);

  static Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    required String errorMessage,
  }) async {
    final resp = await http.get(_uri(path, query));
    return _decode(resp, errorMessage);
  }

  static Future<dynamic> post(
    String path, {
    Map<String, String>? query,
    Object? body,
    required String errorMessage,
  }) async {
    final resp = await http.post(
      _uri(path, query),
      headers: _jsonHeaders(body),
      body: _encodeBody(body),
    );
    return _decode(resp, errorMessage);
  }

  static Future<dynamic> put(
    String path, {
    Map<String, String>? query,
    Object? body,
    required String errorMessage,
  }) async {
    final resp = await http.put(
      _uri(path, query),
      headers: _jsonHeaders(body),
      body: _encodeBody(body),
    );
    return _decode(resp, errorMessage);
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, String>? query,
    Object? body,
    required String errorMessage,
  }) async {
    final resp = await http.delete(
      _uri(path, query),
      headers: _jsonHeaders(body),
      body: _encodeBody(body),
    );
    return _decode(resp, errorMessage);
  }
}
