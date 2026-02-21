import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/app_defaults.dart';
import '../domain/errors/app_exceptions.dart';
import 'logging/app_logger.dart';

class ScheduledAlert {
  /// Creates a scheduled local notification payload.
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
  /// Initializes notification plugin and timezone configuration.
  Future<void> initialize();

  /// Request notification permission.
  ///
  /// Policy: this should be called only as a result of explicit user actions
  /// (e.g., enabling repeat alerts or tapping "test notification"), so the app
  /// does not prompt unexpectedly at launch.
  Future<bool> requestPermission();

  /// Replaces current schedule set with [alerts].
  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  });

  /// Sends an immediate local test notification.
  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  });

  /// Cancels all currently scheduled notifications.
  Future<void> cancelAll();
}

class FlutterNotificationService implements NotificationService {
  /// Creates production notification service backed by plugin APIs.
  FlutterNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  static const _logger = AppLogger(namespace: 'notifications');

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
      _logger.info('timezone initialized: ${tz.local.name}');
    } catch (error, stackTrace) {
      _logger.warning('Failed to read local timezone. Falling back to UTC.');
      _logger.error(
        'timezone init failed',
        error: error,
        stackTrace: stackTrace,
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    _initialized = true;
    _logger.info('notification service initialized');
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    // Platform-specific implementations may be null (e.g., unsupported
    // platforms). In those cases, treat permission as "granted/not required".
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      _logger.info('android notification permission result: $granted');
      return granted ?? true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _logger.info('ios notification permission result: $granted');
      return granted ?? true;
    }

    _logger.debug('permission request skipped for unsupported platform');
    return true;
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
      _logger.info('schedule cleared because alert list is empty');
      return;
    }

    const scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

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
        throw NotificationOperationException(
          code: 'schedule_platform_exception',
          message: 'Failed to schedule notification.',
          cause: e,
        );
      } catch (error) {
        throw NotificationOperationException(
          code: 'schedule_unknown_exception',
          message: 'Unexpected failure while scheduling notifications.',
          cause: error,
        );
      }
    }
    _logger.info('scheduled alerts: ${alerts.length}');
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

    await _plugin.show(AppDefaults.testNotificationId, title, body, details);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _logger.debug('all notifications cancelled');
  }

  /// Builds cross-platform notification payload from current settings.
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
  /// No-op cancel used by tests and non-notification contexts.
  @override
  Future<void> cancelAll() async {}

  /// No-op initialize used by tests and non-notification contexts.
  @override
  Future<void> initialize() async {}

  /// Always grants permission in no-op mode.
  @override
  Future<bool> requestPermission() async => true;

  /// No-op schedule used by tests and non-notification contexts.
  @override
  Future<void> scheduleAlerts({
    required List<ScheduledAlert> alerts,
    required bool vibrationEnabled,
    required String soundType,
  }) async {}

  /// No-op immediate test notification.
  @override
  Future<void> showTest({
    required String title,
    required String body,
    required bool vibrationEnabled,
    required String soundType,
  }) async {}
}
