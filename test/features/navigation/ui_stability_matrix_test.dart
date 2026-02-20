import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_utils.dart';

Future<void> _runParityFlow(
  WidgetTester tester, {
  required Size viewport,
  required double textScale,
}) async {
  setTestViewport(tester, size: viewport);
  tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final fixedNow = DateTime(2026, 2, 20, 9, 0);

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

  expect(find.text('흡연 타이머'), findsOneWidget);
  expect(find.text('지금 흡연 기록'), findsOneWidget);
  expect(find.text('되돌리기'), findsOneWidget);
  expect(tester.takeException(), isNull);

  final addRecordFinder = find.text('지금 흡연 기록').first;
  await tester.ensureVisible(addRecordFinder);
  await tester.tap(addRecordFinder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final undoFinder = find.text('되돌리기').first;
  await tester.ensureVisible(undoFinder);
  await tester.tap(undoFinder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

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

  final resetFinder = find.text('데이터 초기화').first;
  await tester.ensureVisible(resetFinder);
  expect(find.text('데이터 초기화'), findsWidgets);
  expect(tester.takeException(), isNull);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  container.dispose();

  tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const matrix = <String, Size>{
    '320x690': Size(320, 690),
    '360x800': Size(360, 800),
    '390x844': Size(390, 844),
    '412x915': Size(412, 915),
    '915x412': Size(915, 412),
  };
  const scales = <double>[1.0, 1.3, 1.6, 1.8, 2.0];

  for (final viewportEntry in matrix.entries) {
    testWidgets('feature parity + no overflow (${viewportEntry.key})', (
      tester,
    ) async {
      for (final scale in scales) {
        await _runParityFlow(
          tester,
          viewport: viewportEntry.value,
          textScale: scale,
        );
      }
    });
  }
}
