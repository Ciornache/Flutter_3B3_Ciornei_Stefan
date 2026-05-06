import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'backend_service.dart';

class DeviceService {
  static String? _deviceId;

  static String? get cachedDeviceId => _deviceId;

  static Future<String?> _resolveDeviceId() async {
    if (_deviceId != null) return _deviceId;
    if (!Platform.isAndroid) return null;
    final info = await DeviceInfoPlugin().androidInfo;
    _deviceId = info.id;
    return _deviceId;
  }

  static Map<String, Object> _payload(String deviceId, String fcmToken) => {
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': 'android',
      };

  static Future<void> register() async {
    final deviceId = await _resolveDeviceId();
    if (deviceId == null) return;
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
