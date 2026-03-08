import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/domain/app_defaults.dart';
import 'package:smoke_timer/domain/models/app_meta.dart';
import 'package:smoke_timer/domain/models/record_period.dart';
import 'package:smoke_timer/domain/models/smoking_record.dart';
import 'package:smoke_timer/presentation/home/home_widget_presenter.dart';
import 'package:smoke_timer/presentation/state/app_state.dart';

void main() {
  test('buildIfReady returns null before bootstrap completes', () {
    final state = AppState.initial(DateTime(2026, 3, 8, 9, 0));

    final snapshot = HomeWidgetPresenter.buildIfReady(state);

    expect(snapshot, isNull);
  });

  test(
    'build creates active widget payload with elapsed time and summaries',
    () {
      final now = DateTime(2026, 3, 8, 9, 0);
      final lastSmokingAt = DateTime(2026, 3, 8, 8, 15);
      final state = AppState(
        stage: AppStage.main,
        isInitialized: true,
        now: now,
        records: [SmokingRecord(id: '1', timestamp: lastSmokingAt, count: 2)],
        settings: AppDefaults.defaultSettings().copyWith(packPrice: 6000),
        meta: AppMeta(
          hasCompletedOnboarding: true,
          lastSmokingAt: lastSmokingAt,
        ),
        recordPeriod: RecordPeriod.today,
        nextAlertAt: DateTime(2026, 3, 8, 10, 0),
      );

      final snapshot = HomeWidgetPresenter.build(state);

      expect(snapshot.hasRecord, isTrue);
      expect(snapshot.primaryValue, '45분');
      expect(snapshot.statusTitle, isNotEmpty);
      expect(snapshot.statusDetail, isNotEmpty);
      expect(snapshot.nextAlertLabel, isNotEmpty);
      expect(snapshot.nextAlertValue, isNotEmpty);
      expect(snapshot.todayCountLabel, '오늘 2개비');
      expect(snapshot.todaySpendLabel, isNot('가격 설정 필요'));
    },
  );

  test('build creates empty-state payload before first record', () {
    final now = DateTime(2026, 3, 8, 9, 0);
    final state = AppState(
      stage: AppStage.main,
      isInitialized: true,
      now: now,
      records: const [],
      settings: AppDefaults.defaultSettings(),
      meta: const AppMeta(hasCompletedOnboarding: true, lastSmokingAt: null),
      recordPeriod: RecordPeriod.today,
      nextAlertAt: null,
    );

    final snapshot = HomeWidgetPresenter.build(state);

    expect(snapshot.hasRecord, isFalse);
    expect(snapshot.primaryValue, '첫 기록 전');
    expect(snapshot.statusTitle, '첫 기록 후 타이머가 시작돼요');
    expect(snapshot.nextAlertValue, '첫 기록 후 알림이 시작돼요');
    expect(snapshot.todayCountLabel, '오늘 0개비');
    expect(snapshot.todaySpendLabel, '가격 설정 필요');
  });
}
