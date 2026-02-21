import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/presentation/state/app_providers.dart';

import '../../test_utils.dart';

Future<void> _runDarkModeParityFlow(
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

  try {
    await pumpApp(tester, container);

    final skipFinder = find.text('건너뛰기').first;
    await tester.ensureVisible(skipFinder);
    await tester.tap(skipFinder);
    await tester.pumpAndSettle();

    expect(find.text('흡연 타이머'), findsOneWidget);
    expect(find.text('지금 흡연 기록'), findsOneWidget);
    expect(find.text('되돌리기'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();
    expect(find.text('기록'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('다크 모드'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final darkModeFinder = find.text('다크 모드').first;
    await tester.ensureVisible(darkModeFinder);
    await tester.tap(darkModeFinder);
    await tester.pumpAndSettle();

    final appAfterDarkOn = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(appAfterDarkOn.themeMode, ThemeMode.dark);
    expect(
      container.read(appControllerProvider).settings.darkModeEnabled,
      isTrue,
    );
    expect(tester.takeException(), isNull);

    final use24HourBefore = container
        .read(appControllerProvider)
        .settings
        .use24Hour;
    final vibrationBefore = container
        .read(appControllerProvider)
        .settings
        .vibrationEnabled;
    final soundBefore = container
        .read(appControllerProvider)
        .settings
        .soundType;

    final alertFinder = find.text('알림 설정').first;
    await tester.ensureVisible(alertFinder);
    await tester.tap(alertFinder);
    await tester.pumpAndSettle();
    expect(find.text('테스트 알림 보내기'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('설정'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('cost_pack_price_row')));
    await tester.tap(find.byKey(const Key('cost_pack_price_row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cost_input_field')), findsOneWidget);
    expect(find.byKey(const Key('cost_apply_button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final afterCostSheet = container.read(appControllerProvider).settings;
    expect(afterCostSheet.use24Hour, use24HourBefore);
    expect(afterCostSheet.vibrationEnabled, vibrationBefore);
    expect(afterCostSheet.soundType, soundBefore);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('흡연 타이머'), findsOneWidget);
    expect(find.text('지금 흡연 기록'), findsOneWidget);
    expect(find.text('되돌리기'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final addFinder = find.text('지금 흡연 기록').first;
    await tester.ensureVisible(addFinder);
    await tester.tap(addFinder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final undoFinder = find.text('되돌리기').first;
    await tester.ensureVisible(undoFinder);
    await tester.tap(undoFinder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
    tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
  }
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
    testWidgets('dark mode parity + no overflow (${viewportEntry.key})', (
      tester,
    ) async {
      for (final scale in scales) {
        await _runDarkModeParityFlow(
          tester,
          viewport: viewportEntry.value,
          textScale: scale,
        );
      }
    });
  }
}
