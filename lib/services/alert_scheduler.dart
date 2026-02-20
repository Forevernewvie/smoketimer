import '../domain/app_defaults.dart';
import '../domain/models/user_settings.dart';

class AlertScheduler {
  const AlertScheduler();

  /// Builds upcoming alert timestamps using current settings policy.
  ///
  /// The method applies:
  /// 1) repeat flag and required inputs guard
  /// 2) interval/pre-alert offset
  /// 3) allowed weekday/time window alignment
  List<DateTime> buildUpcomingAlerts({
    required DateTime now,
    required DateTime? lastSmokingAt,
    required UserSettings settings,
    required int count,
  }) {
    if (!settings.repeatEnabled || lastSmokingAt == null || count <= 0) {
      return <DateTime>[];
    }
    if (settings.activeWeekdays.isEmpty) {
      return <DateTime>[];
    }

    final interval = Duration(minutes: settings.intervalMinutes);
    var candidate = lastSmokingAt
        .add(interval)
        .subtract(Duration(minutes: settings.preAlertMinutes));

    while (candidate.isBefore(now)) {
      candidate = candidate.add(interval);
    }

    final results = <DateTime>[];
    var guard = 0;

    while (results.length < count &&
        guard < AppDefaults.schedulerBuildGuardLimit) {
      guard += 1;
      final adjusted = alignToAllowedWindow(candidate, settings);
      if (adjusted.isAfter(now) || adjusted.isAtSameMomentAs(now)) {
        if (results.isEmpty || !adjusted.isAtSameMomentAs(results.last)) {
          results.add(adjusted);
        }
      }
      candidate = candidate.add(interval);
    }

    return results;
  }

  /// Returns whether [value] is inside active weekdays and allowed minute range.
  bool isAllowedDateTime(DateTime value, UserSettings settings) {
    if (!settings.activeWeekdays.contains(value.weekday)) {
      return false;
    }

    final minuteOfDay = value.hour * AppDefaults.minutesPerHour + value.minute;
    return minuteOfDay >= settings.allowedStartMinutes &&
        minuteOfDay < settings.allowedEndMinutes;
  }

  /// Aligns [candidate] to the nearest valid window defined in [settings].
  DateTime alignToAllowedWindow(DateTime candidate, UserSettings settings) {
    var result = candidate;
    var guard = 0;

    while (guard < AppDefaults.schedulerAlignGuardLimit) {
      guard += 1;

      final dayStart = DateTime(result.year, result.month, result.day);
      final minuteOfDay =
          result.hour * AppDefaults.minutesPerHour + result.minute;

      if (!settings.activeWeekdays.contains(result.weekday)) {
        result = dayStart
            .add(const Duration(days: 1))
            .add(Duration(minutes: settings.allowedStartMinutes));
        continue;
      }

      if (minuteOfDay < settings.allowedStartMinutes) {
        result = dayStart.add(Duration(minutes: settings.allowedStartMinutes));
        continue;
      }

      if (minuteOfDay >= settings.allowedEndMinutes) {
        result = dayStart
            .add(const Duration(days: 1))
            .add(Duration(minutes: settings.allowedStartMinutes));
        continue;
      }

      return result;
    }

    return result;
  }
}
