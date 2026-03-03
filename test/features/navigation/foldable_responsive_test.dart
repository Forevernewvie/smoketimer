import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

Future<void> _runFoldableFlow(
  WidgetTester tester, {
  required Size viewport,
  required double textScale,
}) async {
  setTestViewport(tester, size: viewport);
  tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final fixedNow = DateTime(2026, 3, 3, 9, 0);

  final container = createTestContainer(
    prefs: prefs,
    now: () => fixedNow,
    autoDispose: false,
  );

  await pumpApp(tester, container);

  final skipFinder = find.text('건너뛰기').first;
  await tester.ensureVisible(skipFinder);
  await tester.tap(skipFinder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  expect(find.text('흡연 타이머'), findsOneWidget);

  await tester.tap(find.text('Record'));
  await tester.pumpAndSettle();
  expect(find.text('기록'), findsOneWidget);
  expect(tester.takeException(), isNull);

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  expect(find.text('설정'), findsOneWidget);
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

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  container.dispose();

  tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Representative logical viewports for Galaxy Foldables.
  const foldableMatrix = <String, Size>{
    // Galaxy Z Flip inner display class (narrow + tall).
    'z_flip_inner_360x880': Size(360, 880),
    // Galaxy Z Fold cover display class.
    'z_fold_cover_360x780': Size(360, 780),
    // Galaxy Z Fold inner display class (tablet-like).
    'z_fold_inner_768x674': Size(768, 674),
    // Galaxy Z Fold inner landscape class.
    'z_fold_inner_landscape_674x768': Size(674, 768),
  };

  const textScales = <double>[1.0, 1.3];

  for (final entry in foldableMatrix.entries) {
    testWidgets('foldable responsiveness ${entry.key}', (tester) async {
      for (final scale in textScales) {
        await _runFoldableFlow(tester, viewport: entry.value, textScale: scale);
      }
    });
  }
}
