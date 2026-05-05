import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/widgets/pen_design_widgets.dart';

import '../../test_utils.dart';

Future<void> _runEnglishLocaleFlow(
  WidgetTester tester, {
  required Size viewport,
  required double textScale,
}) async {
  setTestViewport(tester, size: viewport);
  tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final container = createTestContainer(
    prefs: prefs,
    now: () => DateTime(2026, 5, 5, 12, 0),
    locale: const Locale('en'),
    autoDispose: false,
  );

  await pumpApp(tester, container);
  await tester.ensureVisible(find.text('건너뛰기').first);
  await tester.tap(find.text('건너뛰기').first);
  await tester.pumpAndSettle();

  expect(find.text('흡연 타이머'), findsOneWidget);
  expect(tester.takeException(), isNull);

  await tester.tap(find.text('Record'));
  await tester.pumpAndSettle();
  expect(find.text('기록'), findsOneWidget);
  expect(tester.takeException(), isNull);

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  expect(find.text('Settings'), findsWidgets);
  expect(find.text('Dark Mode'), findsOneWidget);
  expect(tester.takeException(), isNull);

  final alertFinder = find.text('알림 설정').first;
  await tester.ensureVisible(alertFinder);
  await tester.tap(alertFinder);
  await tester.pumpAndSettle();
  expect(find.text('테스트 알림 보내기'), findsOneWidget);
  expect(tester.takeException(), isNull);

  await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final darkModeFinder = find.text('Dark Mode').first;
  await tester.ensureVisible(darkModeFinder);
  expect(tester.takeException(), isNull);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  container.dispose();

  tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long English status chips stay inside constrained cards', (
    tester,
  ) async {
    setTestViewport(tester, size: const Size(320, 690));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 140,
            child: StatusChip(
              text: 'Post-record reminder starts after first entry',
              icon: Icons.notifications_active_outlined,
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  const matrix = <String, Size>{
    'narrow_phone': Size(320, 690),
    'base_phone': Size(390, 844),
    'landscape': Size(915, 412),
  };
  const scales = <double>[1.0, 1.3, 1.6, 2.0];

  for (final entry in matrix.entries) {
    testWidgets('English locale does not overflow on ${entry.key}', (
      tester,
    ) async {
      for (final scale in scales) {
        await _runEnglishLocaleFlow(
          tester,
          viewport: entry.value,
          textScale: scale,
        );
      }
    });
  }
}
