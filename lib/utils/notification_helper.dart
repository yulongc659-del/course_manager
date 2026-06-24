import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _plugin.initialize(settings);
    } catch (_) {}
  }

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(sound: 'default'),
          android: AndroidNotificationDetails(
            'reminder_channel',
            '提醒',
            importance: Importance.high,
          ),
        ),
      );
    } catch (_) {}
  }
}
