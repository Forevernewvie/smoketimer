import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/data/repositories/settings_repository.dart';
import 'package:smoke_timer/data/repositories/smoking_repository.dart';
import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/screens/step1_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reset clears persisted data and returns to onboarding', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final settingsRepo = SettingsRepository(prefs);
    final smokingRepo = SmokingRepository(prefs);

    await settingsRepo.saveMeta(
      AppMeta(
        hasCompletedOnboarding: true,
        lastSmokingAt: DateTime(2026, 2, 17, 8, 0),
      ),
    );
    await smokingRepo.saveRecords([
      SmokingRecord(
        id: 'seed',
        timestamp: DateTime(2026, 2, 17, 8, 0),
        count: 1,
      ),
    ]);

    final notifications = CapturingNotificationService();
    final container = createTestContainer(
      prefs: prefs,
      now: () => DateTime(2026, 2, 17, 9, 0),
      notificationService: notifications,
      autoDispose: false,
    );

    await pumpApp(tester, container);
    expect(find.byType(Step1Screen), findsOneWidget);

    await tester.tap(find.text('04 Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('데이터 초기화'));
    await tester.tap(find.text('데이터 초기화'));
    await tester.pumpAndSettle();

    expect(find.text('데이터 초기화'), findsWidgets);
    await tester.tap(find.text('초기화'));
    await tester.pumpAndSettle();

    expect(find.text('1/3'), findsOneWidget);
    expect(container.read(appControllerProvider).stage.name, 'onboarding');

    expect(prefs.getString('smoking_records_json'), isNull);
    expect(prefs.getString('user_settings_json'), isNull);
    expect(prefs.getString('app_meta_json'), isNull);

    expect(notifications.cancelAllCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
