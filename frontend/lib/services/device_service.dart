import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'backend_service.dart';

class DeviceService {
  static String? _deviceId;

  static String? get cachedDeviceId => _deviceId;

  static Future<String> _resolveDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final box = await Hive.openBox('meta');
    var id = box.get('device_id') as String?;
    if (id == null) {
      id = const Uuid().v4();
      await box.put('device_id', id);
    }
    _deviceId = id;
    return id;
  }

  static Map<String, Object> _payload(String deviceId, String fcmToken) => {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': 'android',
      };

  static Future<void> register() async {
    final deviceId = await _resolveDeviceId();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    await BackendService.post(
      '/devices',
      body: _payload(deviceId, fcmToken),
      errorMessage: 'Device register failed',
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await BackendService.post(
          '/devices',
          body: _payload(deviceId, newToken),
          errorMessage: 'Device token refresh failed',
        );
      } catch (_) {}
    });
  }
}
