import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/services/ads/ad_service.dart';
import 'package:smoke_timer/widgets/main_banner_ad_slot.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'banner slot shows placeholder while loading then collapses on fail',
    (WidgetTester tester) async {
      final adService = TestAdService(
        initialState: const BannerAdState(status: AdBannerStatus.loading),
      );
      addTearDown(adService.disposeService);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBannerAdSlot(adService: adService),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('main_banner_placeholder')), findsOneWidget);
      expect(tester.takeException(), isNull);

      adService.setState(
        BannerAdState(status: AdBannerStatus.failed, error: StateError('fail')),
      );
      await tester.pump();

      expect(find.byKey(const Key('main_banner_hidden')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('step1 screen keeps working when ad service is unavailable', (
    WidgetTester tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final adService = TestAdService(
      initialState: const BannerAdState(status: AdBannerStatus.failed),
    );

    final container = createTestContainer(
      prefs: prefs,
      now: () => DateTime(2026, 2, 17, 9, 0),
      adService: adService,
      autoDispose: false,
    );

    await pumpApp(tester, container);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.text('흡연 타이머'), findsOneWidget);
    expect(find.byKey(const Key('main_banner_hidden')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
    adService.disposeService();
  });
}
