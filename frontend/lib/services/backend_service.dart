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

  static Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final url = _uri(path, query);
    final response = await http.get(url);
    if (response.statusCode != 200) {
        throw Exception('GET $url failed ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body);
  }
}