import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_defaults.dart';
import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../presentation/state/ads_providers.dart';
import '../presentation/state/app_providers.dart';
import '../presentation/state/app_state.dart';
import '../services/ads/ad_service.dart';
import '../services/smoking_stats_service.dart';
import '../services/time_formatter.dart';
import '../widgets/allowed_time_window_sheet.dart';
import '../widgets/main_banner_ad_slot.dart';
import '../widgets/pen_design_widgets.dart';

class Step1Screen extends ConsumerStatefulWidget {
  const Step1Screen({super.key});

  static const routeName = '/step1';

  static const _weekdayLabels = <int, String>{
    DateTime.monday: '월',
    DateTime.tuesday: '화',
    DateTime.wednesday: '수',
    DateTime.thursday: '목',
    DateTime.friday: '금',
    DateTime.saturday: '토',
    DateTime.sunday: '일',
  };

  @override
  ConsumerState<Step1Screen> createState() => _Step1ScreenState();
}

class _Step1ScreenState extends ConsumerState<Step1Screen> {
  int _tabIndex = 0;
  late final AdService _adService;

  static const _pagePadding = EdgeInsets.fromLTRB(24, 24, 24, 24);
  static const _maxContentWidth = 520.0;

  /// Initializes tab-level dependencies and starts banner loading.
  @override
  void initState() {
    super.initState();
    _adService = ref.read(adServiceProvider);
    _adService.loadMainBanner();
  }

  /// Releases ad resources when the main shell is removed.
  @override
  void dispose() {
    _adService.disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    final lastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      state.meta.lastSmokingAt,
      state.records,
    );

    final ringBaseTime = SmokingStatsService.resolveRingBaseTime(
      now: state.now,
      lastSmokingAt: lastSmokingAt,
      settings: state.settings,
    );

    final elapsedSeconds = SmokingStatsService.elapsedSeconds(
      now: state.now,
      ringBaseTime: ringBaseTime,
    );

    final elapsedMinutes = SmokingStatsService.elapsedMinutes(
      now: state.now,
      ringBaseTime: ringBaseTime,
    );

    final ringProgress = SmokingStatsService.ringProgressSeconds(
      elapsedSeconds: elapsedSeconds,
      intervalMinutes: state.settings.intervalMinutes,
    );

    final todayRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.today,
      state.now,
    );

    final todayCount = SmokingStatsService.totalCount(todayRecords);

    final periodRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      state.recordPeriod,
      state.now,
    );

    final totalCount = SmokingStatsService.totalCount(periodRecords);
    final averageInterval = SmokingStatsService.averageIntervalMinutes(
      periodRecords,
    );
    final maxInterval = SmokingStatsService.maxIntervalMinutes(periodRecords);

    final hasIntervalStats = periodRecords.length >= 2;
    final averageIntervalText = hasIntervalStats
        ? '${averageInterval.toString()}분'
        : '-';
    final maxIntervalText = hasIntervalStats
        ? '${maxInterval.toString()}분'
        : '-';

    final nextAlertText = () {
      if (!state.settings.repeatEnabled) {
        return '알림 꺼짐';
      }
      if (lastSmokingAt == null) {
        return '기록 후 알림이 시작돼요';
      }
      if (state.settings.activeWeekdays.isEmpty) {
        return '알림 요일을 선택해주세요';
      }
      if (state.nextAlertAt == null) {
        return '다음 알림 없음';
      }

      final prefix = state.settings.preAlertMinutes > 0 ? '미리 알림까지' : '다음 알림까지';
      return '$prefix ${TimeFormatter.formatCountdown(state.now, state.nextAlertAt!)}';
    }();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _scrollableTab(
              key: const PageStorageKey('tab_home'),
              child: _HomeCard(
                hasRingBaseTime: ringBaseTime != null,
                elapsedMinutes: elapsedMinutes,
                intervalMinutes: state.settings.intervalMinutes,
                ringProgress: ringProgress,
                todayCount: todayCount,
                nextAlertText: nextAlertText,
                onAddRecord: controller.addSmokingRecord,
                onUndoRecord: controller.undoLastRecord,
                onOpenAlertSettings: () => _openAlertSettings(context),
              ),
            ),
            _scrollableTab(
              key: const PageStorageKey('tab_record'),
              child: _RecordCard(
                period: state.recordPeriod,
                records: periodRecords,
                totalCount: totalCount,
                averageIntervalText: averageIntervalText,
                maxIntervalText: maxIntervalText,
                use24Hour: state.settings.use24Hour,
                onPeriodChanged: controller.setRecordPeriod,
              ),
            ),
            _scrollableTab(
              key: const PageStorageKey('tab_settings'),
              child: _SettingsCard(
                use24Hour: state.settings.use24Hour,
                ringReferenceLabel: state.settings.ringReferenceLabel,
                vibrationEnabled: state.settings.vibrationEnabled,
                soundTypeLabel: state.settings.soundTypeLabel,
                alertSummary: state.settings.repeatEnabled
                    ? '켜짐 · ${_formatIntervalLabel(state.settings.intervalMinutes)}'
                    : '꺼짐',
                onToggle24Hour: controller.toggleUse24Hour,
                onCycleRingReference: controller.cycleRingReference,
                onToggleVibration: controller.toggleVibration,
                onCycleSoundType: controller.cycleSoundType,
                onOpenAlertSettings: () => _openAlertSettings(context),
                onResetData: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MainBannerAdSlot(adService: _adService),
          NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (value) {
              setState(() => _tabIndex = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Record',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scrollableTab({required Key key, required Widget child}) {
    return SingleChildScrollView(
      key: key,
      padding: _pagePadding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openAlertSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: '뒤로',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () => Navigator.of(routeContext).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final appState = ref.watch(appControllerProvider);
                              final controller = ref.read(
                                appControllerProvider.notifier,
                              );

                              final rangeText = TimeFormatter.formatRange(
                                startMinutes:
                                    appState.settings.allowedStartMinutes,
                                endMinutes: appState.settings.allowedEndMinutes,
                                use24Hour: appState.settings.use24Hour,
                              );

                              final resolvedLastSmokingAt =
                                  SmokingStatsService.resolveLastSmokingAt(
                                    appState.meta.lastSmokingAt,
                                    appState.records,
                                  );

                              final nextAlertPreviewText = () {
                                if (!appState.settings.repeatEnabled) {
                                  return '꺼짐';
                                }
                                if (resolvedLastSmokingAt == null) {
                                  return '기록 후 시작';
                                }
                                if (appState.settings.activeWeekdays.isEmpty) {
                                  return '요일 필요';
                                }
                                if (appState.nextAlertAt == null) {
                                  return '없음';
                                }

                                final at = TimeFormatter.formatDayAwareClock(
                                  appState.now,
                                  appState.nextAlertAt!,
                                  use24Hour: appState.settings.use24Hour,
                                );
                                final countdown = TimeFormatter.formatCountdown(
                                  appState.now,
                                  appState.nextAlertAt!,
                                );
                                return '$at · $countdown';
                              }();

                              return _AlertCard(
                                repeatEnabled: appState.settings.repeatEnabled,
                                intervalMinutes:
                                    appState.settings.intervalMinutes,
                                preAlertMinutes:
                                    appState.settings.preAlertMinutes,
                                rangeText: rangeText,
                                nextAlertPreviewText: nextAlertPreviewText,
                                activeWeekdays:
                                    appState.settings.activeWeekdays,
                                onToggleRepeat: () async {
                                  final ok = await controller
                                      .toggleRepeatEnabled();
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '알림 권한을 허용해야 반복 알림을 사용할 수 있어요.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onPickInterval: () async {
                                  await _pickIntervalMinutes(
                                    context,
                                    initialMinutes:
                                        appState.settings.intervalMinutes,
                                    onSelected: controller.setIntervalMinutes,
                                  );
                                },
                                onCyclePreAlert:
                                    controller.cyclePreAlertMinutes,
                                onPickRange: () =>
                                    _pickAllowedWindow(context, appState),
                                onToggleWeekday: controller.toggleWeekday,
                                onRequestPermission: () async {
                                  final ok = await controller
                                      .requestNotificationPermission();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '알림 권한이 허용되었습니다.'
                                            : '알림 권한을 허용해주세요. (시스템 설정)',
                                      ),
                                    ),
                                  );
                                },
                                onSendTest: () async {
                                  final ok = await controller
                                      .sendTestNotification();
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('알림 권한이 필요합니다. (시스템 설정)'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickIntervalMinutes(
    BuildContext context, {
    required int initialMinutes,
    required Future<void> Function(int minutes) onSelected,
  }) async {
    final min = AppDefaults.minIntervalMinutes;
    final max = AppDefaults.maxIntervalMinutes;
    final step = AppDefaults.intervalStepMinutes;

    int minutes = initialMinutes.clamp(min, max).toInt();

    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String label = _formatIntervalLabel(minutes);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '간격',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$label (${minutes.toString()}분)',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF2563EB),
                      inactiveTrackColor: const Color(0xFFD9E1EC),
                      thumbColor: const Color(0xFF2563EB),
                      overlayColor: const Color(
                        0xFF2563EB,
                      ).withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      min: min.toDouble(),
                      max: max.toDouble(),
                      divisions: ((max - min) / step).round(),
                      value: minutes.toDouble(),
                      onChanged: (value) {
                        final normalized = ((value / step).round() * step)
                            .clamp(min, max);
                        setModalState(() => minutes = normalized.toInt());
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatIntervalLabel(min),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatIntervalLabel(max),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: '적용',
                    onTap: () {
                      Navigator.of(context).pop(minutes);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null || picked == initialMinutes) {
      return;
    }
    await onSelected(picked);
  }

  static String _formatIntervalLabel(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60).toInt();
    final hours = clamped ~/ 60;
    final remain = clamped % 60;
    if (hours <= 0) {
      return '${clamped.toString()}분';
    }
    if (remain == 0) {
      return '${hours.toString()}시간';
    }
    return '${hours.toString()}시간 ${remain.toString()}분';
  }

  Future<void> _pickAllowedWindow(BuildContext context, AppState state) async {
    final picked = await showAllowedTimeWindowSheet(
      context,
      initialStartMinutes: state.settings.allowedStartMinutes,
      initialEndMinutes: state.settings.allowedEndMinutes,
      use24Hour: state.settings.use24Hour,
    );
    if (picked == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await ref
        .read(appControllerProvider.notifier)
        .updateAllowedTimeWindow(
          startMinutes: picked.startMinutes,
          endMinutes: picked.endMinutes,
        );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('데이터 초기화'),
          content: const Text('기록과 설정을 모두 초기화할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await ref.read(appControllerProvider.notifier).resetAllData();
    }
  }

  // TimeOfDay helper removed: time window is now selected via RangeSlider sheet.
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.intervalMinutes,
    required this.ringProgress,
    required this.todayCount,
    required this.nextAlertText,
    required this.onAddRecord,
    required this.onUndoRecord,
    required this.onOpenAlertSettings,
  });

  final bool hasRingBaseTime;
  final int elapsedMinutes;
  final int intervalMinutes;
  final double ringProgress;
  final int todayCount;
  final String nextAlertText;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;
  final Future<void> Function() onOpenAlertSettings;

  @override
  Widget build(BuildContext context) {
    // Best-effort, user-facing ring meaning:
    // - When there is a base time (usually last smoking), show minutes remaining
    //   until the configured interval. This is the most actionable cue.
    // - If the interval is already exceeded, show overtime minutes instead.
    // - If no base time exists yet, fall back to "0분 경과" (waiting for first record).
    final int ringValueMinutes;
    final String ringLabel;
    if (!hasRingBaseTime) {
      ringValueMinutes = 0;
      ringLabel = '분 경과';
    } else if (intervalMinutes <= 0) {
      ringValueMinutes = 0;
      ringLabel = '분 남음';
    } else if (elapsedMinutes <= intervalMinutes) {
      ringValueMinutes = intervalMinutes - elapsedMinutes;
      ringLabel = '분 남음';
    } else {
      ringValueMinutes = elapsedMinutes - intervalMinutes;
      ringLabel = '분 초과';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '흡연 타이머',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: '알림 설정',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                onPressed: () async {
                  await onOpenAlertSettings();
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              SizedBox(
                height: 210,
                child: Center(
                  child: RingGauge(
                    size: 156,
                    strokeWidth: 10,
                    sweepAngle: ringProgress * 2 * pi,
                    value: ringValueMinutes.toString(),
                    label: ringLabel,
                  ),
                ),
              ),
              Text(
                '설정 간격 ${intervalMinutes.toString()}분',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                text: '지금 흡연 기록',
                onTap: () async {
                  await onAddRecord();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(
                height: 22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '오늘 흡연',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.smoking_rooms_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${todayCount.toString()}개비',
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            height: 36,
                            child: Row(
                              children: [
                                _ActionButton(
                                  text: '되돌리기',
                                  foreground: const Color(0xFF475569),
                                  background: const Color(0xFFEEF2F7),
                                  borderColor: const Color(0xFFD4DCE8),
                                  onTap: onUndoRecord,
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  text: '+1 추가',
                                  foreground: Colors.white,
                                  background: const Color(0xFF2563EB),
                                  onTap: onAddRecord,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nextAlertText,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.borderColor,
  });

  final String text;
  final Color foreground;
  final Color background;
  final Color? borderColor;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.period,
    required this.records,
    required this.totalCount,
    required this.averageIntervalText,
    required this.maxIntervalText,
    required this.use24Hour,
    required this.onPeriodChanged,
  });

  final RecordPeriod period;
  final List<SmokingRecord> records;
  final int totalCount;
  final String averageIntervalText;
  final String maxIntervalText;
  final bool use24Hour;
  final ValueChanged<RecordPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기록',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: _PeriodTab(
                  text: '오늘',
                  selected: period == RecordPeriod.today,
                  onTap: () => onPeriodChanged(RecordPeriod.today),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodTab(
                  text: '주간',
                  selected: period == RecordPeriod.week,
                  onTap: () => onPeriodChanged(RecordPeriod.week),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodTab(
                  text: '월간',
                  selected: period == RecordPeriod.month,
                  onTap: () => onPeriodChanged(RecordPeriod.month),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '총 개비',
                  value: '$totalCount',
                  valueFontSize: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: '평균 간격',
                  value: averageIntervalText,
                  valueFontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: '최장 간격',
                  value: maxIntervalText,
                  valueFontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          cornerRadius: 16,
          child: _RecordList(records: records, use24Hour: use24Hour),
        ),
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(11),
          border: selected ? null : Border.all(color: const Color(0xFFD7DFEA)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueFontSize,
  });

  final String label;
  final String value;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      cornerRadius: 12,
      strokeColor: const Color(0xFFE5E7EB),
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({required this.records, required this.use24Hour});

  final List<SmokingRecord> records;
  final bool use24Hour;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 144,
        child: Center(
          child: Text(
            '기록이 없습니다',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    const maxVisible = 20;
    final visible = records.take(maxVisible).toList();

    return Column(
      children: List.generate(visible.length, (index) {
        final record = visible[index];
        final time = TimeFormatter.formatClock(
          record.timestamp,
          use24Hour: use24Hour,
        );

        return _RecordListRow(
          time: time,
          amount: '+${record.count}개비',
          withTopBorder: index > 0,
        );
      }),
    );
  }
}

class _RecordListRow extends StatelessWidget {
  const _RecordListRow({
    required this.time,
    required this.amount,
    required this.withTopBorder,
  });

  final String time;
  final String amount;
  final bool withTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: withTopBorder
            ? const Border(top: BorderSide(color: Color(0xFFF0F2F5), width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.repeatEnabled,
    required this.intervalMinutes,
    required this.preAlertMinutes,
    required this.rangeText,
    required this.nextAlertPreviewText,
    required this.activeWeekdays,
    required this.onToggleRepeat,
    required this.onPickInterval,
    required this.onCyclePreAlert,
    required this.onPickRange,
    required this.onToggleWeekday,
    required this.onRequestPermission,
    required this.onSendTest,
  });

  final bool repeatEnabled;
  final int intervalMinutes;
  final int preAlertMinutes;
  final String rangeText;
  final String nextAlertPreviewText;
  final Set<int> activeWeekdays;
  final Future<void> Function() onToggleRepeat;
  final Future<void> Function() onPickInterval;
  final Future<void> Function() onCyclePreAlert;
  final Future<void> Function() onPickRange;
  final Future<void> Function(int weekday) onToggleWeekday;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '알림 설정',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            children: [
              _SettingRow(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '반복 알림',
                labelStyle: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                trailing: TogglePill(isOn: repeatEnabled),
                onTap: onToggleRepeat,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '알림 권한',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: '요청',
                withTopBorder: true,
                showChevron: true,
                onTap: onRequestPermission,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '간격',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: '${intervalMinutes.toString()}분',
                withTopBorder: true,
                showChevron: true,
                onTap: onPickInterval,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '미리 알림',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: '${preAlertMinutes.toString()}분 전',
                withTopBorder: true,
                onTap: onCyclePreAlert,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: preAlertMinutes > 0 ? '미리 알림' : '다음 알림',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: nextAlertPreviewText,
                withTopBorder: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '허용 시간대',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: rangeText,
                showChevron: true,
                onTap: onPickRange,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '요일',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 32,
                      child: Row(
                        children: Step1Screen._weekdayLabels.entries
                            .map(
                              (entry) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: entry.key == DateTime.monday ? 0 : 3,
                                    right: entry.key == DateTime.sunday ? 0 : 3,
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await onToggleWeekday(entry.key);
                                    },
                                    child: DayChip(
                                      text: entry.value,
                                      active: activeWeekdays.contains(
                                        entry.key,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: '테스트 알림 보내기',
          color: const Color(0xFF1F2937),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onTap: () async {
            await onSendTest();
          },
        ),
        const SizedBox(height: 16),
        const Text(
          '알림 권한이 꺼져 있으면 시스템 설정에서 켜주세요.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.use24Hour,
    required this.ringReferenceLabel,
    required this.vibrationEnabled,
    required this.soundTypeLabel,
    required this.alertSummary,
    required this.onToggle24Hour,
    required this.onCycleRingReference,
    required this.onToggleVibration,
    required this.onCycleSoundType,
    required this.onOpenAlertSettings,
    required this.onResetData,
  });

  final bool use24Hour;
  final String ringReferenceLabel;
  final bool vibrationEnabled;
  final String soundTypeLabel;
  final String alertSummary;
  final Future<void> Function() onToggle24Hour;
  final Future<void> Function() onCycleRingReference;
  final Future<void> Function() onToggleVibration;
  final Future<void> Function() onCycleSoundType;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onResetData;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '설정',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: _SettingRow(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            label: '알림 설정',
            labelStyle: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            value: alertSummary,
            showChevron: true,
            onTap: onOpenAlertSettings,
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            children: [
              _SettingRow(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '24시간 표기',
                labelStyle: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                trailing: TogglePill(isOn: use24Hour),
                onTap: onToggle24Hour,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '홈 원형 기준',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: ringReferenceLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onCycleRingReference,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '진동',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                withTopBorder: true,
                trailing: TogglePill(isOn: vibrationEnabled),
                onTap: onToggleVibration,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '소리',
                labelStyle: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: soundTypeLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onCycleSoundType,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: _SettingRow(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            label: '데이터 초기화',
            labelStyle: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            onTap: onResetData,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.height,
    required this.padding,
    required this.label,
    required this.labelStyle,
    this.value,
    this.trailing,
    this.withTopBorder = false,
    this.showChevron = false,
    this.onTap,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final String label;
  final TextStyle labelStyle;
  final String? value;
  final Widget? trailing;
  final bool withTopBorder;
  final bool showChevron;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing == null
        ? const <Widget>[]
        : <Widget>[trailing!];

    final content = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        border: withTopBorder
            ? const Border(top: BorderSide(color: Color(0xFFF0F2F5), width: 1))
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          if (value != null)
            Text(
              value!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (value != null && showChevron) const SizedBox(width: 8),
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ...trailingWidgets,
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await onTap!();
      },
      child: content,
    );
  }
}
