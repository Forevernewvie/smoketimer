import 'package:flutter_test/flutter_test.dart';
import 'package:smoke_timer/domain/models/record_period.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/services/smoking_stats_service.dart';

void main() {
  group('SmokingStatsService', () {
    test('average and max interval are calculated from ordered records', () {
      final records = <SmokingRecord>[
        SmokingRecord(
          id: '1',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: '2',
          timestamp: DateTime(2026, 2, 17, 10, 30),
          count: 1,
        ),
        SmokingRecord(
          id: '3',
          timestamp: DateTime(2026, 2, 17, 11, 10),
          count: 1,
        ),
      ];

      expect(SmokingStatsService.averageIntervalMinutes(records), 35);
      expect(SmokingStatsService.maxIntervalMinutes(records), 40);
    });

    test('recordsForPeriod returns only records from selected range', () {
      final now = DateTime(2026, 2, 17, 15, 0);
      final records = <SmokingRecord>[
        SmokingRecord(
          id: 'today',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: 'week',
          timestamp: DateTime(2026, 2, 16, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: 'month',
          timestamp: DateTime(2026, 2, 1, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: 'old',
          timestamp: DateTime(2026, 1, 31, 23, 59),
          count: 1,
        ),
      ];

      final today = SmokingStatsService.recordsForPeriod(
        records,
        RecordPeriod.today,
        now,
      );
      final week = SmokingStatsService.recordsForPeriod(
        records,
        RecordPeriod.week,
        now,
      );
      final month = SmokingStatsService.recordsForPeriod(
        records,
        RecordPeriod.month,
        now,
      );

      expect(today.map((item) => item.id), ['today']);
      expect(week.map((item) => item.id), ['today', 'week']);
      expect(month.map((item) => item.id), ['today', 'week', 'month']);
    });

    test('ring base resolves from dayStart when configured', () {
      final now = DateTime(2026, 2, 17, 12, 0);
      final base = SmokingStatsService.resolveRingBaseTime(
        now: now,
        lastSmokingAt: DateTime(2026, 2, 17, 11, 0),
        settings: const UserSettings(
          intervalMinutes: 45,
          preAlertMinutes: 5,
          repeatEnabled: true,
          allowedStartMinutes: 480,
          allowedEndMinutes: 1440,
          activeWeekdays: {1, 2, 3, 4, 5},
          use24Hour: true,
          ringReference: RingReference.dayStart,
          vibrationEnabled: true,
          soundType: 'default',
        ),
      );

      expect(base, DateTime(2026, 2, 17));
    });
  });
}
