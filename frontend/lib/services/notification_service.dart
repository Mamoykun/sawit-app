// frontend/lib/services/notification_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wrapper untuk flutter_local_notifications.
/// Web: no-op (notification API web kompleks, skip dulu).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize plugin + tz database. Call once at app startup.
  static Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz.initializeTimeZones();
    final localTz = tz.getLocation('Asia/Jakarta');
    tz.setLocalLocation(localTz);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    _initialized = true;

    // Request permission Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Schedule a one-shot notification at [when].
  /// [id] should be stable per-jadwal so reschedule overwrites cleanly.
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return;
    await init();
    if (when.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'sawitku_reminder',
      'Reminder Pemupukan',
      channelDescription: 'Notifikasi jadwal pemupukan kebun sawit',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a scheduled notification.
  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id);
  }

  /// Cancel all (e.g. on logout).
  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }
}
