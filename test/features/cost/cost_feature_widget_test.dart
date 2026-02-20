import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smoke_timer/data/repositories/settings_repository.dart';
import 'package:smoke_timer/data/repositories/smoking_repository.dart';
import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/record_period.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/state/app_providers.dart';
import 'package:smoke_timer/screens/step1_screen.dart';
import 'package:smoke_timer/services/cost_stats_service.dart';
import 'package:smoke_timer/services/smoking_stats_service.dart';

import '../../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> enterCostSheetValue(WidgetTester tester, String value) async {
    await tester.enterText(find.byKey(const Key('cost_input_field')), value);
    await tester.tap(find.byKey(const Key('cost_apply_button')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home shows empty state first, then spend values after pricing set',
    (tester) async {
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

      expect(find.byType(Step1Screen), findsOneWidget);
      expect(find.byKey(const Key('cost_empty_state_text')), findsOneWidget);

      await container.read(appControllerProvider.notifier).setPackPrice(5000);
      await container
          .read(appControllerProvider.notifier)
          .setCigarettesPerPack(20);
      await tester.pumpAndSettle();

      final state = container.read(appControllerProvider);
      final zeroCost = CostStatsService.formatCurrency(0, state.settings);
      expect(find.text('오늘 지출'), findsOneWidget);
      expect(find.text(zeroCost), findsWidgets);

      await tester.tap(find.text('지금 흡연 기록'));
      await tester.pumpAndSettle();

      final afterAdd = container.read(appControllerProvider);
      final expectedSpend = CostStatsService.formatCurrency(
        CostStatsService.computeSpendForCount(
          cigaretteCount: 1,
          settings: afterAdd.settings,
        ),
        afterAdd.settings,
      );
      expect(find.text(expectedSpend), findsWidgets);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(find.text(zeroCost), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );

  testWidgets('Record period filter updates Cost Insights values', (
    tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 2, 17, 9, 0);

    final settingsRepo = SettingsRepository(prefs);
    final smokingRepo = SmokingRepository(prefs);
    final seededSettings = AppDefaults.defaultSettings().copyWith(
      packPrice: 5000,
      cigarettesPerPack: 20,
      currencyCode: 'KRW',
      currencySymbol: '₩',
    );

    await settingsRepo.saveSettings(seededSettings);
    await settingsRepo.saveMeta(
      const AppMeta(hasCompletedOnboarding: true, lastSmokingAt: null),
    );
    await smokingRepo.saveRecords([
      SmokingRecord(
        id: 'today',
        timestamp: DateTime(2026, 2, 17, 8, 30),
        count: 2,
      ),
      SmokingRecord(
        id: 'week',
        timestamp: DateTime(2026, 2, 16, 8, 30),
        count: 1,
      ),
      SmokingRecord(
        id: 'month',
        timestamp: DateTime(2026, 2, 1, 8, 30),
        count: 3,
      ),
    ]);

    final container = createTestContainer(
      prefs: prefs,
      now: () => now,
      autoDispose: false,
    );

    await pumpApp(tester, container);
    expect(find.byType(Step1Screen), findsOneWidget);

    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();

    expect(find.text('비용 인사이트'), findsOneWidget);

    final state = container.read(appControllerProvider);
    final todayRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.today,
      state.now,
    );
    final weekRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.week,
      state.now,
    );
    final monthRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.month,
      state.now,
    );

    final todaySpend = CostStatsService.formatCurrency(
      CostStatsService.computeSpendForRecords(
        records: todayRecords,
        settings: state.settings,
      ),
      state.settings,
    );
    final weekSpend = CostStatsService.formatCurrency(
      CostStatsService.computeSpendForRecords(
        records: weekRecords,
        settings: state.settings,
      ),
      state.settings,
    );
    final monthSpend = CostStatsService.formatCurrency(
      CostStatsService.computeSpendForRecords(
        records: monthRecords,
        settings: state.settings,
      ),
      state.settings,
    );

    expect(find.text(todaySpend), findsWidgets);

    await tester.tap(find.text('주간'));
    await tester.pumpAndSettle();
    expect(find.text(weekSpend), findsWidgets);

    await tester.tap(find.text('월간'));
    await tester.pumpAndSettle();
    expect(find.text(monthSpend), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });

  testWidgets('Settings cost rows persist values across restart', (
    tester,
  ) async {
    setTestViewport(tester, size: const Size(390, 844));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 2, 17, 9, 0);

    var container = createTestContainer(
      prefs: prefs,
      now: () => now,
      autoDispose: false,
    );
    await pumpApp(tester, container);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('cost_pack_price_row')));
    await tester.tap(find.byKey(const Key('cost_pack_price_row')));
    await tester.pumpAndSettle();
    await enterCostSheetValue(tester, '4800');

    await tester.tap(find.byKey(const Key('cost_cigarettes_per_pack_row')));
    await tester.pumpAndSettle();
    await enterCostSheetValue(tester, '19');

    await tester.tap(find.byKey(const Key('cost_currency_row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD (\$)'));
    await tester.pumpAndSettle();

    final firstState = container.read(appControllerProvider);
    expect(firstState.settings.packPrice, 4800);
    expect(firstState.settings.cigarettesPerPack, 19);
    expect(firstState.settings.currencyCode, 'USD');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();

    container = createTestContainer(
      prefs: prefs,
      now: () => now.add(const Duration(minutes: 1)),
      autoDispose: false,
    );
    await pumpApp(tester, container);
    expect(find.byType(Step1Screen), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('USD'), findsWidgets);
    expect(find.text('19개비'), findsOneWidget);
    expect(find.textContaining('4,800'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
  });

  testWidgets(
    'Settings cost input shows inline error and blocks invalid save',
    (tester) async {
      setTestViewport(tester, size: const Size(390, 844));
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 2, 17, 9, 0);

      final container = createTestContainer(
        prefs: prefs,
        now: () => now,
        autoDispose: false,
      );

      await pumpApp(tester, container);
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('cost_pack_price_row')));
      await tester.tap(find.byKey(const Key('cost_pack_price_row')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cost_input_field')),
        '9999999',
      );
      await tester.tap(find.byKey(const Key('cost_apply_button')));
      await tester.pumpAndSettle();

      expect(find.text('허용 범위를 벗어났습니다.'), findsOneWidget);
      expect(container.read(appControllerProvider).settings.packPrice, 0);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    },
  );

  testWidgets('Cost widgets are responsive on 360 and 412 widths', (
    tester,
  ) async {
    final cases = <Size>[const Size(360, 800), const Size(412, 915)];
    for (final size in cases) {
      setTestViewport(tester, size: size);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final container = createTestContainer(
        prefs: prefs,
        now: () => DateTime(2026, 2, 17, 9, 0),
        autoDispose: false,
      );

      await pumpApp(tester, container);
      if (find.text('건너뛰기').evaluate().isNotEmpty) {
        await tester.tap(find.text('건너뛰기'));
        await tester.pumpAndSettle();
      }

      await container.read(appControllerProvider.notifier).setPackPrice(4800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();
      expect(find.text('비용 인사이트'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('갑당 가격'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    }
  });
}
