import 'package:flutter/material.dart';

import '../../services/time_formatter.dart';

/// Semantic tone used to style Home status panels consistently.
enum HomeStatusTone { info, warning, success, risk }

/// Immutable view model consumed by Home status cards.
class HomeStatusPresentation {
  /// Creates a render-ready Home status presentation.
  const HomeStatusPresentation({
    required this.chipText,
    required this.title,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  /// Short label shown in the status chip.
  final String chipText;

  /// Primary status headline.
  final String title;

  /// Supporting explanation under the headline.
  final String detail;

  /// Semantic icon paired with the chip label.
  final IconData icon;

  /// Shared tone token mapped to colors by the widget layer.
  final HomeStatusTone tone;
}

/// Pure input model for interval status decisions.
class HomeIntervalStatusInput {
  /// Creates interval-status input used by [HomeStatusPresenter].
  const HomeIntervalStatusInput({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.intervalMinutes,
  });

  /// Whether a base smoking record exists yet.
  final bool hasRingBaseTime;

  /// Minutes elapsed since the last smoking record.
  final int elapsedMinutes;

  /// Target interval configured for alert timing.
  final int intervalMinutes;
}

/// Pure input model for alert status decisions.
class HomeAlertStatusInput {
  /// Creates alert-status input used by [HomeStatusPresenter].
  const HomeAlertStatusInput({
    required this.hasRingBaseTime,
    required this.repeatEnabled,
    required this.hasSelectedWeekdays,
    required this.preAlertMinutes,
    required this.now,
    required this.nextAlertAt,
    required this.use24Hour,
  });

  /// Whether a base smoking record exists yet.
  final bool hasRingBaseTime;

  /// Whether repeating alerts are enabled.
  final bool repeatEnabled;

  /// Whether at least one weekday is selected for alert recurrence.
  final bool hasSelectedWeekdays;

  /// Minutes used for pre-alert scheduling.
  final int preAlertMinutes;

  /// Time used as the countdown reference point.
  final DateTime now;

  /// Next scheduled alert, if one could be calculated.
  final DateTime? nextAlertAt;

  /// User preference for 12h or 24h clock formatting.
  final bool use24Hour;
}

/// Pure presenter that turns Home status inputs into render-ready view models.
class HomeStatusPresenter {
  /// Prevents accidental instantiation of this pure utility class.
  const HomeStatusPresenter._();

  /// Resolves the interval status shown beside the Home timer hero.
  static HomeStatusPresentation buildIntervalStatus(
    HomeIntervalStatusInput input,
  ) {
    if (!input.hasRingBaseTime) {
      return const HomeStatusPresentation(
        chipText: '기록 대기',
        title: '첫 기록 후 타이머가 시작돼요',
        detail: '기록하면 경과 시간이 움직여요.',
        icon: Icons.play_circle_outline_rounded,
        tone: HomeStatusTone.info,
      );
    }
    if (input.intervalMinutes <= 0) {
      return const HomeStatusPresentation(
        chipText: '설정 필요',
        title: '알림 간격을 설정해 주세요',
        detail: '간격이 있어야 남은 시간을 계산해요.',
        icon: Icons.tune_rounded,
        tone: HomeStatusTone.warning,
      );
    }

    final remainingMinutes = input.intervalMinutes - input.elapsedMinutes;
    if (remainingMinutes > 0) {
      return HomeStatusPresentation(
        chipText: '진행 중',
        title: '$remainingMinutes분 남았어요',
        detail: '간격 ${input.intervalMinutes}분 기준',
        icon: Icons.timer_outlined,
        tone: HomeStatusTone.success,
      );
    }
    if (remainingMinutes == 0) {
      return const HomeStatusPresentation(
        chipText: '확인 시점',
        title: '지금 기록할 타이밍이에요',
        detail: '설정한 간격에 도달했어요.',
        icon: Icons.check_circle_outline_rounded,
        tone: HomeStatusTone.warning,
      );
    }

    final overdueMinutes = input.elapsedMinutes - input.intervalMinutes;
    return HomeStatusPresentation(
      chipText: '간격 초과',
      title: '$overdueMinutes분 지났어요',
      detail: '설정 간격보다 늦었어요.',
      icon: Icons.warning_amber_rounded,
      tone: HomeStatusTone.risk,
    );
  }

  /// Resolves the next-alert status shown in the Home hero panel.
  static HomeStatusPresentation buildAlertStatus(HomeAlertStatusInput input) {
    if (!input.repeatEnabled) {
      return const HomeStatusPresentation(
        chipText: '알림 꺼짐',
        title: '반복 알림이 꺼져 있어요',
        detail: '알림 설정에서 다시 켤 수 있어요.',
        icon: Icons.notifications_off_outlined,
        tone: HomeStatusTone.warning,
      );
    }
    if (!input.hasRingBaseTime) {
      return const HomeStatusPresentation(
        chipText: '기록 후 시작',
        title: '첫 기록 후 알림이 시작돼요',
        detail: '기준 기록이 아직 없어요.',
        icon: Icons.notifications_paused_outlined,
        tone: HomeStatusTone.info,
      );
    }
    if (!input.hasSelectedWeekdays) {
      return const HomeStatusPresentation(
        chipText: '요일 필요',
        title: '알림 요일을 선택해 주세요',
        detail: '요일이 없으면 다음 알림이 없어요.',
        icon: Icons.calendar_month_outlined,
        tone: HomeStatusTone.warning,
      );
    }
    if (input.nextAlertAt == null) {
      return const HomeStatusPresentation(
        chipText: '다음 알림 없음',
        title: '다음 알림을 계산할 수 없어요',
        detail: '시간대와 간격을 확인해 주세요.',
        icon: Icons.schedule_rounded,
        tone: HomeStatusTone.risk,
      );
    }

    final countdown = TimeFormatter.formatCountdown(
      input.now,
      input.nextAlertAt!,
    );
    final alertClock = TimeFormatter.formatDayAwareClock(
      input.now,
      input.nextAlertAt!,
      use24Hour: input.use24Hour,
    );
    return HomeStatusPresentation(
      chipText: input.preAlertMinutes > 0 ? '미리 알림' : '다음 알림',
      title: '$alertClock 예정',
      detail: '$countdown 남았어요.',
      icon: Icons.notifications_active_outlined,
      tone: HomeStatusTone.success,
    );
  }
}
