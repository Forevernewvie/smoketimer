import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/screens/step1_screen.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases = <String, Size>{
    'small': const Size(360, 800),
    'base': const Size(390, 844),
    'large': const Size(800, 900),
  };

  for (final entry in cases.entries) {
    testWidgets(
      'tabs switch without overflow (${entry.key} ${entry.value.width.toInt()}x${entry.value.height.toInt()})',
      (WidgetTester tester) async {
        setTestViewport(tester, size: entry.value);

        SharedPreferences.setMockInitialValues(<String, Object>{});
        final prefs = await SharedPreferences.getInstance();
        final fixedNow = DateTime(2026, 2, 17, 9, 0);

        final container = createTestContainer(
          prefs: prefs,
          now: () => fixedNow,
          autoDispose: false,
        );

        await pumpApp(tester, container);
        await tester.tap(find.text('건너뛰기'));
        await tester.pumpAndSettle();

        expect(find.byType(Step1Screen), findsOneWidget);
        expect(find.text('흡연 타이머'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Record'));
        await tester.pumpAndSettle();
        expect(find.text('기록'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('설정'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('알림 설정'));
        await tester.pumpAndSettle();
        expect(find.text('테스트 알림 보내기'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('설정'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
      },
    );
  }
}
