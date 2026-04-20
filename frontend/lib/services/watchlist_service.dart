import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'device_service.dart';

class WatchlistService {
  static const String boxName = 'watchlist';

  static Box<bool> get _box => Hive.box<bool>(boxName);

  static bool isWatching(int matchId) => _box.containsKey(matchId);

  static Iterable<int> all() => _box.keys.cast<int>();

  static String get _baseUrl => dotenv.env['BACKEND_BASE_URL']!;

  static Future<void> toggle(int matchId) async {
    final deviceId = DeviceService.cachedDeviceId;
    if (deviceId == null) {
      throw Exception('Device not registered');
    }

    if (isWatching(matchId)) {
      await _unsubscribe(deviceId, matchId);
      await _box.delete(matchId);
    } else {
      await _subscribe(deviceId, matchId);
      await _box.put(matchId, true);
    }
  }

  static Future<void> _subscribe(String deviceId, int matchId) async {
    final url = Uri.parse('$_baseUrl/devices/$deviceId/watchlist/$matchId');
    final resp = await http.put(url);
    if (resp.statusCode != 200) {
      throw Exception('Subscribe failed ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<void> _unsubscribe(String deviceId, int matchId) async {
    final url = Uri.parse('$_baseUrl/devices/$deviceId/watchlist')
        .replace(queryParameters: {'matchId': matchId.toString()});
    final resp = await http.delete(url);
    if (resp.statusCode != 200) {
      throw Exception('Unsubscribe failed ${resp.statusCode}: ${resp.body}');
    }
  }
}
