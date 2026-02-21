import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/presentation/state/app_providers.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pre-alert minutes are adjusted with 0~15 slider', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = createTestContainer(
      prefs: prefs,
      now: () => DateTime(2026, 2, 17, 9, 0),
      autoDispose: false,
    );

    await pumpApp(tester, container);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('알림 설정'));
    await tester.pumpAndSettle();

    final sliderFinder = find.byKey(const Key('pre_alert_slider'));
    expect(sliderFinder, findsOneWidget);

    final initialSlider = tester.widget<Slider>(sliderFinder);
    expect(initialSlider.min, 0);
    expect(initialSlider.max, 15);
    expect(initialSlider.divisions, 15);

    initialSlider.onChanged?.call(12.0);
    await tester.pumpAndSettle();

    expect(container.read(appControllerProvider).settings.preAlertMinutes, 12);
    expect(find.text('12분 전'), findsOneWidget);
    expect(find.text('미리 알림'), findsWidgets);
    expect(tester.takeException(), isNull);

    final updatedSlider = tester.widget<Slider>(sliderFinder);
    updatedSlider.onChanged?.call(0.0);
    await tester.pumpAndSettle();

    expect(container.read(appControllerProvider).settings.preAlertMinutes, 0);
    expect(find.text('0분 전'), findsOneWidget);
    expect(find.text('다음 알림'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
