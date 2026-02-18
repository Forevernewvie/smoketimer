import 'dart:math';

import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../domain/models/user_settings.dart';

class SmokingStatsService {
  const SmokingStatsService._();

  static DateTime? resolveLastSmokingAt(
    DateTime? metaLastSmokingAt,
    List<SmokingRecord> records,
  ) {
    if (metaLastSmokingAt != null) {
      return metaLastSmokingAt;
    }
    if (records.isEmpty) {
      return null;
    }
    return records.first.timestamp;
  }

  static DateTime? resolveRingBaseTime({
    required DateTime now,
    required DateTime? lastSmokingAt,
    required UserSettings settings,
  }) {
    switch (settings.ringReference) {
      case RingReference.lastSmoking:
        return lastSmokingAt;
      case RingReference.dayStart:
        return DateTime(now.year, now.month, now.day);
    }
  }

  static int elapsedMinutes({
    required DateTime now,
    required DateTime? ringBaseTime,
  }) {
    if (ringBaseTime == null) {
      return 0;
    }
    return max(0, now.difference(ringBaseTime).inMinutes);
  }

  static int elapsedSeconds({
    required DateTime now,
    required DateTime? ringBaseTime,
  }) {
    if (ringBaseTime == null) {
      return 0;
    }
    return max(0, now.difference(ringBaseTime).inSeconds);
  }

  static double ringProgress({
    required int elapsedMinutes,
    required int intervalMinutes,
  }) {
    if (intervalMinutes <= 0) {
      return 0;
    }
    return (elapsedMinutes / intervalMinutes).clamp(0.0, 1.0);
  }

  static double ringProgressSeconds({
    required int elapsedSeconds,
    required int intervalMinutes,
  }) {
    if (intervalMinutes <= 0) {
      return 0;
    }
    final totalSeconds = intervalMinutes * 60;
    if (totalSeconds <= 0) {
      return 0;
    }
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  static List<SmokingRecord> recordsForPeriod(
    List<SmokingRecord> all,
    RecordPeriod period,
    DateTime now,
  ) {
    final sorted = [...all]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final start = switch (period) {
      RecordPeriod.today => DateTime(now.year, now.month, now.day),
      RecordPeriod.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      RecordPeriod.month => DateTime(now.year, now.month, 1),
    };

    return sorted
        .where((record) => !record.timestamp.isBefore(start))
        .toList(growable: false);
  }

  static int totalCount(List<SmokingRecord> records) {
    return records.fold(0, (sum, item) => sum + item.count);
  }

  static int averageIntervalMinutes(List<SmokingRecord> records) {
    final intervals = _intervalMinutes(records);
    if (intervals.isEmpty) {
      return 0;
    }
    final total = intervals.reduce((a, b) => a + b);
    return (total / intervals.length).round();
  }

  static int maxIntervalMinutes(List<SmokingRecord> records) {
    final intervals = _intervalMinutes(records);
    if (intervals.isEmpty) {
      return 0;
    }
    return intervals.reduce(max);
  }

  static List<int> _intervalMinutes(List<SmokingRecord> records) {
    if (records.length < 2) {
      return <int>[];
    }

    final ordered = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final intervals = <int>[];
    for (var index = 1; index < ordered.length; index += 1) {
      final diff = ordered[index].timestamp
          .difference(ordered[index - 1].timestamp)
          .inMinutes;
      if (diff > 0) {
        intervals.add(diff);
      }
    }
    return intervals;
  }
}
