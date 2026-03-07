import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/presentation/alert/alert_settings_presenter.dart';

void main() {
  test('repeat-disabled state collapses alert summary to off', () {
    final presentation = AlertSettingsPresenter.build(
      AlertSettingsInput(
        repeatEnabled: false,
        intervalMinutes: 45,
        preAlertMinutes: 0,
        allowedStartMinutes: 480,
        allowedEndMinutes: 1320,
        use24Hour: true,
        hasRingBaseTime: true,
        activeWeekdayCount: 5,
        now: DateTime(2026, 2, 17, 9, 0),
        nextAlertAt: DateTime(2026, 2, 17, 9, 45),
      ),
    );

    expect(presentation.settingsSummary, '꺼짐');
    expect(presentation.nextAlertPreviewText, '꺼짐');
    expect(presentation.repeatChipTone, AlertSettingsTone.warning);
  });

  test('formatIntervalLabel returns compact hour and minute labels', () {
    expect(AlertSettingsPresenter.formatIntervalLabel(30), '30분');
    expect(AlertSettingsPresenter.formatIntervalLabel(120), '2시간');
    expect(AlertSettingsPresenter.formatIntervalLabel(135), '2시간 15분');
  });

  test('alert preview waits for first record before scheduling', () {
    final presentation = AlertSettingsPresenter.build(
      AlertSettingsInput(
        repeatEnabled: true,
        intervalMinutes: 60,
        preAlertMinutes: 5,
        allowedStartMinutes: 480,
        allowedEndMinutes: 1320,
        use24Hour: true,
        hasRingBaseTime: false,
        activeWeekdayCount: 3,
        now: DateTime(2026, 2, 17, 9, 0),
        nextAlertAt: null,
      ),
    );

    expect(presentation.nextAlertPreviewText, '기록 후 시작');
    expect(presentation.scheduleChipText, '5분 미리 알림');
    expect(presentation.nextAlertRowLabel, '미리 알림');
  });

  test('weekday summary warns when no active weekdays are selected', () {
    final presentation = AlertSettingsPresenter.build(
      AlertSettingsInput(
        repeatEnabled: true,
        intervalMinutes: 60,
        preAlertMinutes: 0,
        allowedStartMinutes: 480,
        allowedEndMinutes: 1320,
        use24Hour: true,
        hasRingBaseTime: true,
        activeWeekdayCount: 0,
        now: DateTime(2026, 2, 17, 9, 0),
        nextAlertAt: null,
      ),
    );

    expect(presentation.weekdayCountText, '없음');
    expect(presentation.weekdayTone, AlertSettingsTone.warning);
    expect(presentation.showWeekdayHint, isTrue);
  });

  test('alert preview shows none when schedule cannot be calculated', () {
    final presentation = AlertSettingsPresenter.build(
      AlertSettingsInput(
        repeatEnabled: true,
        intervalMinutes: 60,
        preAlertMinutes: 0,
        allowedStartMinutes: 480,
        allowedEndMinutes: 1320,
        use24Hour: true,
        hasRingBaseTime: true,
        activeWeekdayCount: 3,
        now: DateTime(2026, 2, 17, 9, 0),
        nextAlertAt: null,
      ),
    );

    expect(presentation.nextAlertPreviewText, '없음');
    expect(presentation.nextAlertRowLabel, '다음 알림');
  });

  test(
    'resolved alert schedule formats preview and summaries consistently',
    () {
      final presentation = AlertSettingsPresenter.build(
        AlertSettingsInput(
          repeatEnabled: true,
          intervalMinutes: 90,
          preAlertMinutes: 10,
          allowedStartMinutes: 480,
          allowedEndMinutes: 1320,
          use24Hour: true,
          hasRingBaseTime: true,
          activeWeekdayCount: 4,
          now: DateTime(2026, 2, 17, 9, 0),
          nextAlertAt: DateTime(2026, 2, 17, 10, 30),
        ),
      );

      expect(presentation.settingsSummary, '켜짐 · 1시간 30분');
      expect(presentation.intervalLabel, '1시간 30분');
      expect(presentation.rangeText, '08:00 ~ 22:00');
      expect(presentation.nextAlertPreviewText, '10:30 · 01:30');
      expect(presentation.repeatChipIcon, Icons.notifications_active_outlined);
      expect(presentation.repeatChipTone, AlertSettingsTone.success);
    },
  );
}
