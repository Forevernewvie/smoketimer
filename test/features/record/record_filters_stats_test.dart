import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/models/record_period.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/services/smoking_stats_service.dart';

void main() {
  group('RecordPeriod filtering', () {
    test('recordsForPeriod splits today/week/month by date boundary', () {
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
  });

  group('SmokingStatsService calculations', () {
    test('total/average/max interval are calculated from records', () {
      final records = <SmokingRecord>[
        SmokingRecord(
          id: '1',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: '2',
          timestamp: DateTime(2026, 2, 17, 10, 30),
          count: 2,
        ),
        SmokingRecord(
          id: '3',
          timestamp: DateTime(2026, 2, 17, 11, 10),
          count: 1,
        ),
      ];

      expect(SmokingStatsService.totalCount(records), 4);
      expect(SmokingStatsService.averageIntervalMinutes(records), 35);
      expect(SmokingStatsService.maxIntervalMinutes(records), 40);
    });

    test('edge cases: empty/one record return 0 interval stats', () {
      expect(SmokingStatsService.averageIntervalMinutes(const []), 0);
      expect(SmokingStatsService.maxIntervalMinutes(const []), 0);

      final single = <SmokingRecord>[
        SmokingRecord(
          id: 'only',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
      ];
      expect(SmokingStatsService.averageIntervalMinutes(single), 0);
      expect(SmokingStatsService.maxIntervalMinutes(single), 0);
    });

    test('edge cases: identical timestamps are ignored for intervals', () {
      final records = <SmokingRecord>[
        SmokingRecord(
          id: 'a',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
        SmokingRecord(
          id: 'b',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
      ];

      expect(SmokingStatsService.averageIntervalMinutes(records), 0);
      expect(SmokingStatsService.maxIntervalMinutes(records), 0);
    });

    test('ordering: reversed records still produce correct interval stats', () {
      final records = <SmokingRecord>[
        SmokingRecord(
          id: 'late',
          timestamp: DateTime(2026, 2, 17, 11, 0),
          count: 1,
        ),
        SmokingRecord(
          id: 'early',
          timestamp: DateTime(2026, 2, 17, 10, 0),
          count: 1,
        ),
      ];

      expect(SmokingStatsService.averageIntervalMinutes(records), 60);
      expect(SmokingStatsService.maxIntervalMinutes(records), 60);
    });
  });
}
