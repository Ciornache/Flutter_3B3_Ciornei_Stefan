import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';

  static String _urlFor(String? sport) {
    switch ((sport ?? 'Football').toLowerCase()) {
      case 'nfl':
        return dotenv.env['API_NFL_BASE_URL'] ?? '';
      case 'afl':
        return dotenv.env['API_AFL_BASE_URL'] ?? '';
      case 'hockey':
        return dotenv.env['API_HOCKEY_BASE_URL'] ?? '';
      case 'football':
      default:
        return dotenv.env['API_FOOTBALL_BASE_URL'] ?? '';
    }
  }

  static Future<http.Response> get(String endpoint, {String? sport}) async {
    final url = Uri.parse('${_urlFor(sport)}$endpoint');
    print('GET $url');
    final response = await http.get(
      url,
      headers: {'x-apisports-key': _apiKey},
    );
    print('GET $endpoint → ${response.statusCode} (${response.bodyBytes.length} bytes)');
    return response;
  }

  ApiService();
}
