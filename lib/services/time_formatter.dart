import 'package:intl/intl.dart';

import '../domain/app_defaults.dart';

class TimeFormatter {
  const TimeFormatter._();

  /// Formats [value] into a clock string based on 12h/24h preference.
  static String formatClock(DateTime value, {required bool use24Hour}) {
    final format = use24Hour ? DateFormat('HH:mm') : DateFormat('a h:mm');
    return format.format(value);
  }

  /// Formats time with date prefix when [value] is not the same day as [now].
  static String formatDayAwareClock(
    DateTime now,
    DateTime value, {
    required bool use24Hour,
  }) {
    final sameDay =
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
    final clock = formatClock(value, use24Hour: use24Hour);
    if (sameDay) {
      return clock;
    }
    final date = DateFormat('M/d').format(value);
    return '$date $clock';
  }

  /// Formats minute-of-day into user-facing clock text.
  static String formatMinutesToClock(int minutes, {required bool use24Hour}) {
    // Policy:
    // - 24:00 is only valid in 24-hour format.
    // - In 12-hour format, represent "end of day" as 00:00 (midnight).
    final isEndOfDay = minutes >= AppDefaults.minutesPerDay;

    final normalized = isEndOfDay
        ? 0
        : minutes.clamp(0, AppDefaults.minutesPerDay - 1);
    final hour = normalized ~/ AppDefaults.minutesPerHour;
    final minute = normalized % AppDefaults.minutesPerHour;

    if (use24Hour) {
      if (isEndOfDay) {
        return '24:00';
      }
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final dt = DateTime(2026, 1, 1, hour, minute);
    return DateFormat('a h:mm').format(dt);
  }

  /// Formats start/end minute window into a single range string.
  static String formatRange({
    required int startMinutes,
    required int endMinutes,
    required bool use24Hour,
  }) {
    return '${formatMinutesToClock(startMinutes, use24Hour: use24Hour)} ~ '
        '${formatMinutesToClock(endMinutes, use24Hour: use24Hour)}';
  }

  /// Formats remaining countdown time to `hh:mm` or `mm:ss`.
  static String formatCountdown(DateTime now, DateTime target) {
    final diff = target.difference(now);
    if (diff.isNegative) {
      return '00:00';
    }

    final totalSeconds = diff.inSeconds;
    final hours = totalSeconds ~/ AppDefaults.secondsPerHour;
    final minutes =
        (totalSeconds % AppDefaults.secondsPerHour) ~/
        AppDefaults.secondsPerMinute;
    final seconds = totalSeconds % AppDefaults.secondsPerMinute;

    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      final mm = minutes.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
