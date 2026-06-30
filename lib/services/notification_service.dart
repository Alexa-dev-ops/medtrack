import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Handles all local (on-device) notification scheduling for medication
/// reminders. No server / Firebase involvement — the OS fires these even
/// if the app is fully closed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Call once, early in app startup (e.g. in main() before runApp).
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Uses the device's actual local timezone so schedules fire at the
    // correct wall-clock time regardless of where the user is.
    final String localTz = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Fallback: if the platform timezone name isn't recognized by the
      // `timezone` package database, default to UTC offset-based local.
      tz.setLocalLocation(tz.local);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings: initSettings);

    // Android 13+ requires runtime notification permission.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Schedules a daily repeating reminder for a medication at a given
  /// hour/minute. Returns the notification id used, so it can be stored
  /// alongside the medication record for later cancellation/editing.
  ///
  /// [baseId] should be unique per medication+time pair (see
  /// `NotificationService.idFor` below for a stable way to generate it).
  Future<void> scheduleDailyReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medication',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: id,
      title: 'Time to take $medicationName',
      body: 'Dosage: $dosage',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Repeats daily at the same hour:minute.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels a single scheduled reminder by its notification id.
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancels every reminder tied to a medication (call this with all the
  /// ids you generated for that medication's times before deleting it).
  Future<void> cancelAll(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  /// Deterministically derives a notification id from a medication id and
  /// the index of its reminder time, so the same medication+time always
  /// maps to the same id (needed for editing/cancelling later).
  static int idFor(int medicationId, int timeIndex) {
    return (medicationId * 100) + timeIndex;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
