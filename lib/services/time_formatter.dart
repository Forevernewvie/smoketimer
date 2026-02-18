import 'package:intl/intl.dart';

class TimeFormatter {
  const TimeFormatter._();

  static String formatClock(DateTime value, {required bool use24Hour}) {
    final format = use24Hour ? DateFormat('HH:mm') : DateFormat('a h:mm');
    return format.format(value);
  }

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

  static String formatMinutesToClock(int minutes, {required bool use24Hour}) {
    // Policy:
    // - 24:00 is only valid in 24-hour format.
    // - In 12-hour format, represent "end of day" as 00:00 (midnight).
    final isEndOfDay = minutes >= 1440;

    final normalized = isEndOfDay ? 0 : minutes.clamp(0, 1439);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;

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

  static String formatRange({
    required int startMinutes,
    required int endMinutes,
    required bool use24Hour,
  }) {
    return '${formatMinutesToClock(startMinutes, use24Hour: use24Hour)} ~ '
        '${formatMinutesToClock(endMinutes, use24Hour: use24Hour)}';
  }

  static String formatCountdown(DateTime now, DateTime target) {
    final diff = target.difference(now);
    if (diff.isNegative) {
      return '00:00';
    }

    final totalSeconds = diff.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

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
