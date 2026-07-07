import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a gentle daily local notification — "Your daily bread is ready" —
/// inviting the member to read the Word and pray. Repeats every morning.
class DailyReminderService {
  DailyReminderService._();
  static final DailyReminderService instance = DailyReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1001;
  static const _hour = 7; // 7:00 AM local

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      // Device timezone if the plugin is available; otherwise fall back so the
      // reminder still schedules (just at the fallback zone's 7am).
      try {
        final localName = (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (e) {
        debugPrint('DailyReminderService: timezone lookup failed ($e) — using fallback');
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestSoundPermission: true,
            requestBadgePermission: true,
          ),
        ),
      );

      await _schedule();
    } catch (e) {
      debugPrint('DailyReminderService: init failed — $e');
    }
  }

  Future<void> _schedule() async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: _id,
      title: 'Your daily bread is ready',
      body:
          'Take a moment to read the Word and pray. Give us this day our daily bread.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bw_daily',
          'Daily bread',
          channelDescription: 'A gentle morning reminder to read and pray',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }
}
