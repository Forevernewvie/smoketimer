import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/presentation/home/home_status_presenter.dart';

void main() {
  test('interval status shows waiting state before first record', () {
    const input = HomeIntervalStatusInput(
      hasRingBaseTime: false,
      elapsedMinutes: 0,
      intervalMinutes: 30,
    );

    final presentation = HomeStatusPresenter.buildIntervalStatus(input);

    expect(presentation.chipText, '기록 대기');
    expect(presentation.tone, HomeStatusTone.info);
    expect(presentation.icon, Icons.play_circle_outline_rounded);
  });

  test('interval status shows remaining minutes while timer is active', () {
    const input = HomeIntervalStatusInput(
      hasRingBaseTime: true,
      elapsedMinutes: 12,
      intervalMinutes: 30,
    );

    final presentation = HomeStatusPresenter.buildIntervalStatus(input);

    expect(presentation.chipText, '진행 중');
    expect(presentation.title, '18분 남았어요');
    expect(presentation.detail, '간격 30분 기준');
    expect(presentation.tone, HomeStatusTone.success);
  });

  test('interval status shows overdue warning after interval passes', () {
    const input = HomeIntervalStatusInput(
      hasRingBaseTime: true,
      elapsedMinutes: 48,
      intervalMinutes: 30,
    );

    final presentation = HomeStatusPresenter.buildIntervalStatus(input);

    expect(presentation.chipText, '간격 초과');
    expect(presentation.title, '18분 지났어요');
    expect(presentation.tone, HomeStatusTone.risk);
  });

  test('alert status shows disabled state when repeat is off', () {
    final input = HomeAlertStatusInput(
      hasRingBaseTime: true,
      repeatEnabled: false,
      hasSelectedWeekdays: true,
      preAlertMinutes: 0,
      now: DateTime(2026, 2, 17, 9, 0),
      nextAlertAt: DateTime(2026, 2, 17, 9, 30),
      use24Hour: true,
    );

    final presentation = HomeStatusPresenter.buildAlertStatus(input);

    expect(presentation.chipText, '알림 꺼짐');
    expect(presentation.tone, HomeStatusTone.warning);
  });

  test('alert status requires weekday selection before scheduling', () {
    final input = HomeAlertStatusInput(
      hasRingBaseTime: true,
      repeatEnabled: true,
      hasSelectedWeekdays: false,
      preAlertMinutes: 0,
      now: DateTime(2026, 2, 17, 9, 0),
      nextAlertAt: null,
      use24Hour: true,
    );

    final presentation = HomeStatusPresenter.buildAlertStatus(input);

    expect(presentation.chipText, '요일 필요');
    expect(presentation.title, '알림 요일을 선택해 주세요');
    expect(presentation.tone, HomeStatusTone.warning);
  });

  test('alert status shows next alert countdown when schedule exists', () {
    final input = HomeAlertStatusInput(
      hasRingBaseTime: true,
      repeatEnabled: true,
      hasSelectedWeekdays: true,
      preAlertMinutes: 5,
      now: DateTime(2026, 2, 17, 9, 0),
      nextAlertAt: DateTime(2026, 2, 17, 9, 30),
      use24Hour: true,
    );

    final presentation = HomeStatusPresenter.buildAlertStatus(input);

    expect(presentation.chipText, '미리 알림');
    expect(presentation.title, '09:30 예정');
    expect(presentation.detail, '30:00 남았어요.');
    expect(presentation.tone, HomeStatusTone.success);
  });
}
