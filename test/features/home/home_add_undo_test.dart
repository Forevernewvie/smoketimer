import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/screens/step1_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home add record and undo updates state and reschedules alerts', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 2, 17, 9, 0);

    final notifications = CapturingNotificationService();
    final container = createTestContainer(
      prefs: prefs,
      now: () => now,
      notificationService: notifications,
      autoDispose: false,
    );

    await pumpApp(tester, container);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(find.byType(Step1Screen), findsOneWidget);

    await tester.tap(find.text('지금 흡연 기록'));
    await tester.pumpAndSettle();

    expect(find.text('1개비'), findsOneWidget);

    final afterAdd = container.read(appControllerProvider);
    expect(afterAdd.records.length, 1);
    expect(afterAdd.meta.lastSmokingAt, now);

    final expectedFirst = now.add(const Duration(minutes: 40));
    final expectedSecond = now.add(const Duration(minutes: 85));
    expect(afterAdd.nextAlertAt, expectedFirst);

    expect(notifications.scheduledBatches, isNotEmpty);
    final scheduled = notifications.scheduledBatches.last;
    expect(scheduled.length, 3);
    expect(scheduled[0].at, expectedFirst);
    expect(scheduled[1].at, expectedSecond);

    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('0개비'), findsOneWidget);

    final afterUndo = container.read(appControllerProvider);
    expect(afterUndo.records, isEmpty);
    expect(afterUndo.meta.lastSmokingAt, isNull);
    expect(afterUndo.nextAlertAt, isNull);
    expect(notifications.scheduledBatches.last, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
