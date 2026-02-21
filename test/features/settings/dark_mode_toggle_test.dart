import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/domain/models/user_settings.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void expectUnchangedSettingsFields(
    UserSettings actual,
    UserSettings baseline,
  ) {
    expect(actual.intervalMinutes, baseline.intervalMinutes);
    expect(actual.preAlertMinutes, baseline.preAlertMinutes);
    expect(actual.repeatEnabled, baseline.repeatEnabled);
    expect(actual.allowedStartMinutes, baseline.allowedStartMinutes);
    expect(actual.allowedEndMinutes, baseline.allowedEndMinutes);
    expect(setEquals(actual.activeWeekdays, baseline.activeWeekdays), isTrue);
    expect(actual.use24Hour, baseline.use24Hour);
    expect(actual.ringReference, baseline.ringReference);
    expect(actual.vibrationEnabled, baseline.vibrationEnabled);
    expect(actual.soundType, baseline.soundType);
    expect(actual.packPrice, baseline.packPrice);
    expect(actual.cigarettesPerPack, baseline.cigarettesPerPack);
    expect(actual.currencyCode, baseline.currencyCode);
    expect(actual.currencySymbol, baseline.currencySymbol);
  }

  testWidgets('dark mode toggle updates theme and persists after restart', (
    tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final fixedNow = DateTime(2026, 2, 20, 9, 0);

    final container = createTestContainer(
      prefs: prefs,
      now: () => fixedNow,
      autoDispose: false,
    );
    await pumpApp(tester, container);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('다크 모드'), findsOneWidget);
    final initialSettings = container.read(appControllerProvider).settings;
    expect(initialSettings.darkModeEnabled, isFalse);

    await tester.tap(find.text('다크 모드').first);
    await tester.pumpAndSettle();

    final afterDarkOn = container.read(appControllerProvider).settings;
    expect(afterDarkOn.darkModeEnabled, isTrue);
    expectUnchangedSettingsFields(afterDarkOn, initialSettings);

    final appAfterDarkOn = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appAfterDarkOn.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('다크 모드').first);
    await tester.pumpAndSettle();

    final afterDarkOff = container.read(appControllerProvider).settings;
    expect(afterDarkOff.darkModeEnabled, isFalse);
    expectUnchangedSettingsFields(afterDarkOff, initialSettings);

    final appAfterDarkOff = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(appAfterDarkOff.themeMode, ThemeMode.light);
    expect(tester.takeException(), isNull);

    // Keep dark mode enabled, then verify persistence after restart.
    await tester.tap(find.text('다크 모드').first);
    await tester.pumpAndSettle();
    expect(
      container.read(appControllerProvider).settings.darkModeEnabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();

    final restartedContainer = createTestContainer(
      prefs: prefs,
      now: () => fixedNow,
      autoDispose: false,
    );
    await pumpApp(tester, restartedContainer);

    expect(
      restartedContainer.read(appControllerProvider).settings.darkModeEnabled,
      isTrue,
    );
    expectUnchangedSettingsFields(
      restartedContainer.read(appControllerProvider).settings,
      initialSettings,
    );
    final appAfterRestart = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(appAfterRestart.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);

    restartedContainer.dispose();
  });
}
