import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/services/alert_scheduler.dart';

void main() {
  group('AlertScheduler', () {
    const scheduler = AlertScheduler();

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
      packPrice: 4500,
      cigarettesPerPack: 20,
      currencyCode: 'KRW',
      currencySymbol: '₩',
    );

    test('buildUpcomingAlerts returns interval-based next notifications', () {
      final now = DateTime(2026, 2, 17, 9, 0); // Tue
      final lastSmokingAt = DateTime(2026, 2, 17, 8, 30);

      final alerts = scheduler.buildUpcomingAlerts(
        now: now,
        lastSmokingAt: lastSmokingAt,
        settings: settings,
        count: 3,
      );

      expect(alerts.length, 3);
      expect(alerts.first, DateTime(2026, 2, 17, 9, 10));
      expect(alerts[1], DateTime(2026, 2, 17, 9, 55));
    });

    test(
      'alignToAllowedWindow shifts early-morning candidate to start time',
      () {
        final candidate = DateTime(2026, 2, 17, 0, 20); // Tue 00:20
        final aligned = scheduler.alignToAllowedWindow(candidate, settings);

        expect(aligned, DateTime(2026, 2, 17, 8, 0));
      },
    );

    test('alignToAllowedWindow skips inactive weekdays (e.g., weekend)', () {
      final candidate = DateTime(2026, 2, 21, 10, 0); // Sat
      final aligned = scheduler.alignToAllowedWindow(candidate, settings);

      expect(aligned, DateTime(2026, 2, 23, 8, 0)); // Mon 08:00
    });

    test('returns empty when no active weekday exists', () {
      final emptyWeekdaySettings = settings.copyWith(activeWeekdays: <int>{});
      final alerts = scheduler.buildUpcomingAlerts(
        now: DateTime(2026, 2, 17, 9, 0),
        lastSmokingAt: DateTime(2026, 2, 17, 8, 30),
        settings: emptyWeekdaySettings,
        count: 3,
      );

      expect(alerts, isEmpty);
    });
  });
}
