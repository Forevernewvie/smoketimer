import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/presentation/state/app_providers.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('allowed time window is edited via bottom sheet', (
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

    await tester.tap(find.text('Alert'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('허용 시간대'));
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(RangeSlider);
    expect(sliderFinder, findsOneWidget);

    final slider = tester.widget<RangeSlider>(sliderFinder);
    slider.onChanged?.call(const RangeValues(540, 600)); // 09:00 ~ 10:00
    await tester.pump();

    await tester.tap(find.byKey(const Key('allowed_window_apply')));
    await tester.pumpAndSettle();

    final state = container.read(appControllerProvider);
    expect(state.settings.allowedStartMinutes, 540);
    expect(state.settings.allowedEndMinutes, 600);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });

  testWidgets('apply is disabled when end <= start', (
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

    await tester.tap(find.text('Alert'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('허용 시간대'));
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(RangeSlider);
    expect(sliderFinder, findsOneWidget);

    final slider = tester.widget<RangeSlider>(sliderFinder);
    slider.onChanged?.call(const RangeValues(600, 600)); // invalid
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find.byKey(const Key('allowed_window_apply_opacity')),
    );
    expect(opacity.opacity, 0.4);

    await tester.tap(find.byKey(const Key('allowed_window_apply')));
    await tester.pumpAndSettle();
    expect(find.byType(RangeSlider), findsOneWidget);

    await tester.tap(find.byKey(const Key('allowed_window_cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(RangeSlider), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });
}
