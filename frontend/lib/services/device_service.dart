import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  static Future<void> register() async {
    final deviceId = await _resolveDeviceId();
    if (deviceId == null) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final base = dotenv.env['BACKEND_BASE_URL']!;
    final resp = await http.post(
      Uri.parse('$base/devices'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': 'android',
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Device register failed ${resp.statusCode}: ${resp.body}');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await http.post(
        Uri.parse('$base/devices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'fcmToken': newToken,
          'platform': 'android',
        }),
      );
    });
  }
}
