import '../../domain/app_defaults.dart';
import '../../domain/models/smoking_record.dart';
import '../../domain/models/user_settings.dart';
import '../../services/logging/app_logger.dart';
import '../../services/notification_service.dart';
import '../../services/smoking_stats_service.dart';
import 'app_config.dart';
import 'app_ports.dart';

/// Immutable result returned after rebuilding notification schedules.
class NotificationRescheduleResult {
  /// Creates a render-agnostic notification reschedule result.
  const NotificationRescheduleResult({
    required this.nextAlertAt,
    required this.alerts,
  });

  /// First upcoming alert or null when no valid schedule exists.
  final DateTime? nextAlertAt;

  /// Notification payloads registered for the current schedule state.
  final List<ScheduledAlert> alerts;
}

/// Coordinates alert computation and notification registration.
class AppNotificationCoordinator {
  /// Creates a coordinator with explicit scheduling and delivery dependencies.
  const AppNotificationCoordinator({
    required AlertSchedulingPolicy scheduler,
    required NotificationService notificationService,
    required AppConfig config,
    AppLogger logger = const AppLogger(namespace: 'notification-coordinator'),
  }) : _scheduler = scheduler,
       _notificationService = notificationService,
       _config = config,
       _logger = logger;

  final AlertSchedulingPolicy _scheduler;
  final NotificationService _notificationService;
  final AppConfig _config;
  final AppLogger _logger;

  /// Rebuilds upcoming alerts from the provided state snapshot and registers them.
  Future<NotificationRescheduleResult> reschedule({
    required DateTime now,
    required DateTime? lastSmokingAt,
    required List<SmokingRecord> records,
    required UserSettings settings,
  }) async {
    final normalizedLastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      lastSmokingAt,
      records,
    );

    final upcoming = _scheduler.buildUpcomingAlerts(
      now: now,
      lastSmokingAt: normalizedLastSmokingAt,
      settings: settings,
      count: _config.scheduleCount,
    );

    final alerts = _buildScheduledAlerts(upcoming);
    await _notificationService.scheduleAlerts(
      alerts: alerts,
      vibrationEnabled: settings.vibrationEnabled,
      soundType: settings.soundType,
    );

    _logger.info('rescheduled notifications: ${alerts.length}');
    return NotificationRescheduleResult(
      nextAlertAt: upcoming.isEmpty ? null : upcoming.first,
      alerts: alerts,
    );
  }

  /// Converts raw timestamps into stable notification payload identifiers.
  List<ScheduledAlert> _buildScheduledAlerts(List<DateTime> upcoming) {
    final alerts = <ScheduledAlert>[];
    for (var index = 0; index < upcoming.length; index += 1) {
      alerts.add(
        ScheduledAlert(
          id: AppDefaults.scheduledAlertIdBase + index,
          at: upcoming[index],
          title: AppDefaults.alertNotificationTitle,
          body: AppDefaults.alertNotificationBody,
        ),
      );
    }
    return List<ScheduledAlert>.unmodifiable(alerts);
  }
}
