import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _primaryKey = dotenv.env['API_KEY'] ?? '';
  static final String _secondaryKey = dotenv.env['SECOND_API_KEY'] ?? '';

  static String _urlFor(String? sport) {
    switch ((sport ?? 'football').toLowerCase()) {
      case 'football':
      default:
        return dotenv.env['API_FOOTBALL_BASE_URL'] ?? '';
    }
  }

  static Future<http.Response> get(String endpoint, {String? sport}) async {
    final url = Uri.parse('${_urlFor(sport)}$endpoint');
    print('GET $url');

    var response = await _send(url, _primaryKey);
    if (_quotaExhausted(response) && _secondaryKey.isNotEmpty) {
      print('Primary API key exhausted → retrying with secondary');
      response = await _send(url, _secondaryKey);
    }
    return response;
  }

  static Future<http.Response> _send(Uri url, String key) async {
    final response = await http.get(url, headers: {'x-apisports-key': key});
    print('GET $url → ${response.statusCode} (${response.bodyBytes.length} bytes)');
    return response;
  }

  static bool _quotaExhausted(http.Response r) {
    if (r.statusCode == 429) return true;
    if (r.statusCode != 200) return false;
    try {
      final json = jsonDecode(r.body);
      if (json is! Map) return false;
      final errors = json['errors'];
      if (errors is Map) {
        return errors['rateLimit'] != null || errors['requests'] != null;
      }
    } catch (_) {}
    return false;
  }

  ApiService();
}
