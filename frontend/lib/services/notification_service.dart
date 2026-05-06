import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/fixture.dart';
import '../screens/match_detail_screen.dart';
import 'backend_service.dart';

const _kChannelId = 'match_events';
const _kChannelName = 'Match events';
const _kChannelDesc = 'Live match goals, cards, and updates';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.showLocal(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _navigateFromPayload(response.payload);
      },
    );

   
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.high,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
    final granted = await android?.requestNotificationsPermission();

    print('[NotificationService] android notif permission: $granted');
    

    FirebaseMessaging.onMessage.listen((msg) {
      print('[NotificationService] onMessage fired: data=${msg.data}');
      showLocal(msg);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _navigateFromData(msg.data);
    });

    final token = await FirebaseMessaging.instance.getToken();

    print('[NotificationService] FCM token: $token');
  }

  static Future<void> handleInitialMessage() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _navigateFromData(initial.data);
    }
  }

  static Future<void> showLocal(RemoteMessage msg) async {
    final data = msg.data;
    final title = data['title']?.toString();
    final body = data['body']?.toString();
    print('[NotificationService] showLocal title=$title body=$body data=$data');
    if (title == null || body == null) return;

    final payload = [
      data['matchId']?.toString() ?? '',
      data['sport']?.toString() ?? '',
      data['date']?.toString() ?? '',
    ].join('|');

    try {
      await _plugin.show(
        msg.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: _kChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: payload,
      );
      print('[NotificationService] _plugin.show OK id=${msg.hashCode}');
    } catch (e, st) {
      print('[NotificationService] _plugin.show FAILED: $e\n$st');
    }
  }

  static void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    if (parts.length < 3) return;
    _navigateFromData({
      'matchId': parts[0],
      'sport': parts[1],
      'date': parts[2],
    });
  }

  static Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final matchId = data['matchId']?.toString() ?? '';
    final sport = data['sport']?.toString() ?? '';
    final date = data['date']?.toString() ?? '';
    if (matchId.isEmpty || sport.isEmpty || date.isEmpty) return;

    try {
      final json = await BackendService.get(
        '/fixtures/$sport/$matchId',
        query: {'date': date},
        errorMessage: 'Failed to load fixture',
      );
      final fixture = Fixture.fromJson(json as Map<String, dynamic>);
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.push(MaterialPageRoute(
        builder: (_) => MatchDetailScreen(fixture: fixture),
      ));
    } catch (e) {
      print('[NotificationService] navigate failed: $e');
    }
  }
}
