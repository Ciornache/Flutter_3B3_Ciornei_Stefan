import 'package:http/http.dart' as http;

class EspnService {
  static const String _baseUrl = 'https://site.api.espn.com/apis/site/v2/sports';

  static const Map<String, String> sportIdToEspnSlug = {
    'basketball': 'basketball',
    'american_football': 'football',
    'hockey': 'hockey',
  };

  static Future<http.Response> scoreboard({
    required String sportId,
    required String leagueSlug,
    String? date,
  }) async {
    final sportSlug = sportIdToEspnSlug[sportId];
    if (sportSlug == null) {
      throw ArgumentError('No ESPN slug for sport $sportId');
    }
    final query = date != null ? '?dates=$date' : '';
    final url = Uri.parse('$_baseUrl/$sportSlug/$leagueSlug/scoreboard$query');
    print('GET $url');
    final response = await http.get(url);
    print('GET $url → ${response.statusCode} (${response.bodyBytes.length} bytes)');
    return response;
  }

  static Future<http.Response> summary({
    required String sportId,
    required String leagueSlug,
    required String eventId,
  }) async {
    final sportSlug = sportIdToEspnSlug[sportId];
    if (sportSlug == null) {
      throw ArgumentError('No ESPN slug for sport $sportId');
    }
    final url = Uri.parse('$_baseUrl/$sportSlug/$leagueSlug/summary?event=$eventId');
    print('GET $url');
    final response = await http.get(url);
    print('GET $url → ${response.statusCode} (${response.bodyBytes.length} bytes)');
    return response;
  }

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
