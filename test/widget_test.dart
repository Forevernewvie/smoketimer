import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/main.dart';
import 'package:smoke_timer/presentation/state/app_config.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/screens/step1_screen.dart';
import 'package:smoke_timer/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding completion persists and home add/undo works', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 2200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final fixedNow = DateTime(2026, 2, 17, 9, 0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(
            NoopNotificationService(),
          ),
          appConfigProvider.overrideWithValue(
            const AppConfig(splashDuration: Duration.zero, scheduleCount: 3),
          ),
          nowProvider.overrideWithValue(() => fixedNow),
        ],
        child: const SmokeTimerApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);

    await tester.ensureVisible(find.text('건너뛰기'));
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.byType(Step1Screen), findsOneWidget);

    await tester.tap(find.text('지금 흡연 기록'));
    await tester.pumpAndSettle();
    expect(find.text('1개비'), findsOneWidget);

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('0개비'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final restartedPrefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(restartedPrefs),
          notificationServiceProvider.overrideWithValue(
            NoopNotificationService(),
          ),
          appConfigProvider.overrideWithValue(
            const AppConfig(splashDuration: Duration.zero, scheduleCount: 3),
          ),
          nowProvider.overrideWithValue(() => fixedNow),
        ],
        child: const SmokeTimerApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(Step1Screen), findsOneWidget);
  });
}
