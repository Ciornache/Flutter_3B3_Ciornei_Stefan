import 'package:hive/hive.dart';

import 'backend_service.dart';
import 'device_service.dart';

class WatchlistService {
  static const String boxName = 'watchlist';

  static Box<bool> get _box => Hive.box<bool>(boxName);

  static bool isWatching(int matchId) => _box.containsKey(matchId);

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
    await BackendService.put(
      '/devices/$deviceId/watchlist/$matchId',
      errorMessage: 'Subscribe failed',
    );
  }

  static Future<void> _unsubscribe(String deviceId, int matchId) async {
    await BackendService.delete(
      '/devices/$deviceId/watchlist',
      query: {'matchId': matchId.toString()},
      errorMessage: 'Unsubscribe failed',
    );
  }
}
