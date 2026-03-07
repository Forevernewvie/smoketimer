import 'package:flutter/material.dart';

import '../../services/time_formatter.dart';

/// Semantic tone used by alert settings chips and warnings.
enum AlertSettingsTone { info, warning, success, risk }

/// Pure input model used to build alert settings presentation data.
class AlertSettingsInput {
  /// Creates the immutable input required for alert settings rendering.
  const AlertSettingsInput({
    required this.repeatEnabled,
    required this.intervalMinutes,
    required this.preAlertMinutes,
    required this.allowedStartMinutes,
    required this.allowedEndMinutes,
    required this.use24Hour,
    required this.hasRingBaseTime,
    required this.activeWeekdayCount,
    required this.now,
    required this.nextAlertAt,
  });

  /// Whether repeating alerts are currently enabled.
  final bool repeatEnabled;

  /// Current alert interval in minutes.
  final int intervalMinutes;

  /// Current pre-alert lead time in minutes.
  final int preAlertMinutes;

  /// Allowed start minute for scheduling.
  final int allowedStartMinutes;

  /// Allowed end minute for scheduling.
  final int allowedEndMinutes;

  /// Whether clocks should use 24-hour formatting.
  final bool use24Hour;

  /// Whether a last-smoking anchor exists for alert scheduling.
  final bool hasRingBaseTime;

  /// Number of selected active weekdays.
  final int activeWeekdayCount;

  /// Current wall-clock time for countdown formatting.
  final DateTime now;

  /// Next resolved alert schedule, if any.
  final DateTime? nextAlertAt;
}

/// Render-ready view model for the alert settings screen and summary rows.
class AlertSettingsPresentation {
  /// Creates an immutable render model for alert settings UI.
  const AlertSettingsPresentation({
    required this.repeatEnabled,
    required this.preAlertMinutes,
    required this.repeatChipText,
    required this.repeatChipIcon,
    required this.repeatChipTone,
    required this.scheduleChipText,
    required this.scheduleChipTone,
    required this.nextAlertPreviewText,
    required this.nextAlertRowLabel,
    required this.intervalLabel,
    required this.rangeText,
    required this.weekdayCountText,
    required this.weekdayTone,
    required this.showWeekdayHint,
    required this.preAlertValueText,
    required this.settingsSummary,
  });

  /// Whether the repeat toggle is active.
  final bool repeatEnabled;

  /// Current pre-alert lead time used by the slider and labels.
  final int preAlertMinutes;

  /// Status chip copy for the repeat-toggle state.
  final String repeatChipText;

  /// Status chip icon for the repeat-toggle state.
  final IconData repeatChipIcon;

  /// Semantic tone for the repeat status chip.
  final AlertSettingsTone repeatChipTone;

  /// Secondary status chip copy for schedule timing mode.
  final String scheduleChipText;

  /// Semantic tone for the timing chip.
  final AlertSettingsTone scheduleChipTone;

  /// Human-readable next alert preview for overview and settings rows.
  final String nextAlertPreviewText;

  /// Label used for the next-alert settings row.
  final String nextAlertRowLabel;

  /// User-facing interval label without raw minute duplication.
  final String intervalLabel;

  /// User-facing allowed scheduling range.
  final String rangeText;

  /// Condensed weekday activity summary.
  final String weekdayCountText;

  /// Semantic tone for the weekday summary chip.
  final AlertSettingsTone weekdayTone;

  /// Whether the weekday helper hint should be shown.
  final bool showWeekdayHint;

  /// Human-readable pre-alert summary shown beside the slider.
  final String preAlertValueText;

  /// Compact summary used in the main Settings tab.
  final String settingsSummary;
}

/// Pure presenter that centralizes alert settings formatting and state copy.
class AlertSettingsPresenter {
  /// Prevents accidental instantiation of this pure utility class.
  const AlertSettingsPresenter._();

  /// Builds a full alert settings render model from immutable input data.
  static AlertSettingsPresentation build(AlertSettingsInput input) {
    final intervalLabel = formatIntervalLabel(input.intervalMinutes);
    final rangeText = TimeFormatter.formatRange(
      startMinutes: input.allowedStartMinutes,
      endMinutes: input.allowedEndMinutes,
      use24Hour: input.use24Hour,
    );

    final nextAlertPreviewText = _buildNextAlertPreviewText(input);
    final hasWeekdays = input.activeWeekdayCount > 0;

    return AlertSettingsPresentation(
      repeatEnabled: input.repeatEnabled,
      preAlertMinutes: input.preAlertMinutes,
      repeatChipText: input.repeatEnabled ? '반복 알림 켜짐' : '반복 알림 꺼짐',
      repeatChipIcon: input.repeatEnabled
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      repeatChipTone: input.repeatEnabled
          ? AlertSettingsTone.success
          : AlertSettingsTone.warning,
      scheduleChipText: input.preAlertMinutes > 0
          ? '${input.preAlertMinutes}분 미리 알림'
          : '정시 알림',
      scheduleChipTone: AlertSettingsTone.info,
      nextAlertPreviewText: nextAlertPreviewText,
      nextAlertRowLabel: input.preAlertMinutes > 0 ? '미리 알림' : '다음 알림',
      intervalLabel: intervalLabel,
      rangeText: rangeText,
      weekdayCountText: hasWeekdays ? '${input.activeWeekdayCount}일' : '없음',
      weekdayTone: hasWeekdays
          ? AlertSettingsTone.info
          : AlertSettingsTone.warning,
      showWeekdayHint: !hasWeekdays,
      preAlertValueText: '${input.preAlertMinutes}분 전',
      settingsSummary: input.repeatEnabled ? '켜짐 · $intervalLabel' : '꺼짐',
    );
  }

  /// Formats interval minutes into a compact Korean label for settings UI.
  static String formatIntervalLabel(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60).toInt();
    final hours = clamped ~/ 60;
    final remain = clamped % 60;
    if (hours <= 0) {
      return '$clamped분';
    }
    if (remain == 0) {
      return '$hours시간';
    }
    return '$hours시간 $remain분';
  }

  /// Resolves the next alert preview text without leaking scheduling details.
  static String _buildNextAlertPreviewText(AlertSettingsInput input) {
    if (!input.repeatEnabled) {
      return '꺼짐';
    }
    if (!input.hasRingBaseTime) {
      return '기록 후 시작';
    }
    if (input.activeWeekdayCount <= 0) {
      return '요일 필요';
    }
    if (input.nextAlertAt == null) {
      return '없음';
    }

    final alertClock = TimeFormatter.formatDayAwareClock(
      input.now,
      input.nextAlertAt!,
      use24Hour: input.use24Hour,
    );
    final countdown = TimeFormatter.formatCountdown(
      input.now,
      input.nextAlertAt!,
    );
    return '$alertClock · $countdown';
  }
}
