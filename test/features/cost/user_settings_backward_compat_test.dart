import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/user_settings.dart';

void main() {
  test(
    'UserSettings.fromJson keeps backward compatibility for missing cost fields',
    () {
      final defaults = AppDefaults.defaultSettings();

      final legacyJson = <String, dynamic>{
        'intervalMinutes': 45,
        'preAlertMinutes': 5,
        'repeatEnabled': true,
        'allowedStartMinutes': 480,
        'allowedEndMinutes': 1440,
        'activeWeekdays': [1, 2, 3, 4, 5],
        'use24Hour': true,
        'ringReference': 'lastSmoking',
        'vibrationEnabled': true,
        'soundType': 'default',
      };

      final parsed = UserSettings.fromJson(legacyJson, defaults: defaults);
      expect(parsed.packPrice, defaults.packPrice);
      expect(parsed.cigarettesPerPack, defaults.cigarettesPerPack);
      expect(parsed.currencyCode, defaults.currencyCode);
      expect(parsed.currencySymbol, defaults.currencySymbol);
    },
  );

  test('missing weekday list falls back to default weekdays', () {
    final defaults = AppDefaults.defaultSettings();
    final json = <String, dynamic>{
      'intervalMinutes': 45,
      'preAlertMinutes': 5,
      'repeatEnabled': true,
      'allowedStartMinutes': 480,
      'allowedEndMinutes': 1440,
      'use24Hour': true,
      'ringReference': 'lastSmoking',
      'vibrationEnabled': true,
      'soundType': 'default',
    };

    final parsed = UserSettings.fromJson(json, defaults: defaults);
    expect(parsed.activeWeekdays, isNotEmpty);
    expect(parsed.activeWeekdays, defaults.activeWeekdays);
  });
}
