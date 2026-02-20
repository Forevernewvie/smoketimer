import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final viewports = <String, Size>{
    // Galaxy compact class
    'galaxy_compact': const Size(360, 800),
    // Galaxy Plus/Ultra representative logical viewport
    'galaxy_large': const Size(412, 915),
    // Narrow fallback class
    'narrow_android': const Size(320, 690),
    // Galaxy landscape check
    'galaxy_landscape': const Size(915, 412),
  };

  for (final entry in viewports.entries) {
    testWidgets('no overflow on ${entry.key} at supported text scales', (
      tester,
    ) async {
      final scales = entry.key == 'galaxy_landscape'
          ? const <double>[1.0, 1.3]
          : const <double>[1.0, 1.3, 1.6];
      for (final scale in scales) {
        setTestViewport(tester, size: entry.value);
        tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );

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

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.text('설정'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
      }
    });
  }
}
