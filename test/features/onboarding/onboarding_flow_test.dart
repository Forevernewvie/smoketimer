import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/data/repositories/settings_repository.dart';
import 'package:smoke_timer/screens/step1_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding completion persists and restart goes to main', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final fixedNow = DateTime(2026, 2, 17, 9, 0);

    final container = createTestContainer(
      prefs: prefs,
      now: () => fixedNow,
      autoDispose: false,
    );
    await pumpApp(tester, container);

    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.byType(Step1Screen), findsOneWidget);

    final meta = await SettingsRepository(prefs).loadMeta();
    expect(meta.hasCompletedOnboarding, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();

    final restartedContainer = createTestContainer(
      prefs: prefs,
      now: () => fixedNow,
      autoDispose: false,
    );
    await pumpApp(tester, restartedContainer);
    expect(find.byType(Step1Screen), findsOneWidget);

    restartedContainer.dispose();
  });
}
