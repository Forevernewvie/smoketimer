import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/presentation/state/app_settings_policy.dart';

void main() {
  /// Builds a stable settings fixture for policy tests.
  UserSettings createSettings() => AppDefaults.defaultSettings();

  test('setIntervalMinutes clamps values into supported policy range', () {
    final current = createSettings();

    final updated = AppSettingsPolicy.setIntervalMinutes(current, 9999);

    expect(updated, isNotNull);
    expect(updated!.intervalMinutes, AppDefaults.maxIntervalMinutes);
  });

  test('cycle settings advance through configured options', () {
    final current = createSettings();

    final interval = AppSettingsPolicy.cycleIntervalMinutes(current);
    final preAlert = AppSettingsPolicy.cyclePreAlertMinutes(current);
    final sound = AppSettingsPolicy.cycleSoundType(current);

    expect(interval.intervalMinutes, 60);
    expect(preAlert.preAlertMinutes, 10);
    expect(sound.soundType, 'silent');
  });

  test('updateAllowedTimeWindow rejects invalid ranges', () {
    final current = createSettings();

    final updated = AppSettingsPolicy.updateAllowedTimeWindow(
      current,
      startMinutes: 1200,
      endMinutes: 600,
    );

    expect(updated, isNull);
  });

  test('setCurrencyCode normalizes casing and resolves symbol', () {
    final current = createSettings();

    final updated = AppSettingsPolicy.setCurrencyCode(current, ' usd ');

    expect(updated, isNotNull);
    expect(updated!.currencyCode, 'USD');
    expect(updated.currencySymbol, '\$');
  });
}
