import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/models/record_period.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/services/cost_stats_service.dart';

void main() {
  const settings = UserSettings(
    intervalMinutes: 45,
    preAlertMinutes: 5,
    repeatEnabled: true,
    allowedStartMinutes: 8 * 60,
    allowedEndMinutes: 24 * 60,
    activeWeekdays: {1, 2, 3, 4, 5},
    use24Hour: true,
    ringReference: RingReference.lastSmoking,
    vibrationEnabled: true,
    soundType: 'default',
    packPrice: 5000,
    cigarettesPerPack: 20,
    currencyCode: 'KRW',
    currencySymbol: '₩',
  );

  test('unit cost and spend are computed deterministically', () {
    expect(CostStatsService.computeUnitCost(settings), 250);
    expect(
      CostStatsService.computeSpendForCount(
        cigaretteCount: 3,
        settings: settings,
      ),
      750,
    );
  });

  test('invalid values are clamped and never negative/NaN', () {
    expect(CostStatsService.normalizePackPrice(-1), 0);
    expect(CostStatsService.normalizePackPrice(999999), 200000);
    expect(CostStatsService.normalizeCigarettesPerPack(0), 1);
    expect(CostStatsService.normalizeCigarettesPerPack(999), 60);
  });

  test('period spend and average daily spend follow policy', () {
    final now = DateTime(2026, 2, 17, 12, 0);
    final weekRecords = <SmokingRecord>[
      SmokingRecord(id: 'a', timestamp: DateTime(2026, 2, 17, 10, 0), count: 2),
      SmokingRecord(id: 'b', timestamp: DateTime(2026, 2, 16, 10, 0), count: 1),
    ];

    final weekSpend = CostStatsService.computeSpendForRecords(
      records: weekRecords,
      settings: settings,
    );
    expect(weekSpend, 750);

    final weekDaily = CostStatsService.computeAverageDailySpend(
      period: RecordPeriod.week,
      now: now,
      periodRecords: weekRecords,
      settings: settings,
    );
    expect(weekDaily, closeTo(107.1428, 0.001));

    final monthDaily = CostStatsService.computeAverageDailySpend(
      period: RecordPeriod.month,
      now: now,
      periodRecords: weekRecords,
      settings: settings,
    );
    expect(monthDaily, closeTo(26.7857, 0.001));
  });

  test('currency formatting uses configured symbol and safe fallback', () {
    expect(CostStatsService.formatCurrency(2500, settings), contains('₩'));

    const usd = UserSettings(
      intervalMinutes: 45,
      preAlertMinutes: 5,
      repeatEnabled: true,
      allowedStartMinutes: 8 * 60,
      allowedEndMinutes: 24 * 60,
      activeWeekdays: {1, 2, 3, 4, 5},
      use24Hour: true,
      ringReference: RingReference.lastSmoking,
      vibrationEnabled: true,
      soundType: 'default',
      packPrice: 10,
      cigarettesPerPack: 20,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );

    final usdText = CostStatsService.formatCurrency(12.34, usd);
    expect(usdText, contains('\$'));
  });
}
