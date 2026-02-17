import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ScheduledAlert {
  const ScheduledAlert({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
}

abstract class NotificationService {
  Future<void> initialize();

  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  });

  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  });

  Future<void> cancelAll();
}

class FlutterNotificationService implements NotificationService {
  FlutterNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'smoke_timer_alerts';
  static const _channelName = 'Smoke Timer Alerts';
  static const _channelDescription = '흡연 간격 알림 채널';

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  @override
  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  }) async {
    await initialize();
    await cancelAll();

    if (alerts.isEmpty) {
      return;
    }

    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    for (final alert in alerts) {
      final details = _notificationDetails(
        vibrationEnabled: vibrationEnabled,
        soundType: soundType,
      );

      try {
        await _plugin.zonedSchedule(
          alert.id,
          alert.title,
          alert.body,
          tz.TZDateTime.from(alert.at, tz.local),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: scheduleMode,
        );
      } on PlatformException catch (e) {
        // Android 12+ may disallow exact alarms unless user grants special access.
        // In that case, fall back to inexact scheduling so the app still works.
        if (e.code == 'exact_alarms_not_permitted' &&
            scheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          await _plugin.zonedSchedule(
            alert.id,
            alert.title,
            alert.body,
            tz.TZDateTime.from(alert.at, tz.local),
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: scheduleMode,
          );
          continue;
        }
        rethrow;
      }
    }
  }

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  }) async {
    await initialize();
    final details = _notificationDetails(
      vibrationEnabled: vibrationEnabled,
      soundType: soundType,
    );

    if (kDebugMode) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        final canExact = await androidPlugin.canScheduleExactNotifications();
        debugPrint(
          '[notifications] enabled=$enabled canScheduleExact=$canExact tz=${tz.local.name}',
        );
      }
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[notifications] pending=${pending.length}');
    }

    await _plugin.show(900001, title, body, details);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _notificationDetails({
    required bool vibrationEnabled,
    required String soundType,
  }) {
    final silent = soundType == 'silent';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: vibrationEnabled,
        playSound: !silent,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: !silent,
      ),
    );
  }
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  }) async {}

  @override
  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  }) async {}
}
