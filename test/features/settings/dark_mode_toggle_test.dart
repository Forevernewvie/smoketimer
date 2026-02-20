import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/presentation/state/app_providers.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    expect(
      container.read(appControllerProvider).settings.darkModeEnabled,
      isFalse,
    );

    await tester.tap(find.text('다크 모드').first);
    await tester.pumpAndSettle();

    expect(
      container.read(appControllerProvider).settings.darkModeEnabled,
      isTrue,
    );

    final appAfterToggle = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appAfterToggle.themeMode, ThemeMode.dark);
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
    final appAfterRestart = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(appAfterRestart.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);

    restartedContainer.dispose();
  });
}
