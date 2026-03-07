import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_defaults.dart';
import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../l10n/app_localizations.dart';
import '../presentation/alert/alert_settings_presenter.dart';
import '../presentation/home/home_status_presenter.dart';
import '../presentation/state/ads_providers.dart';
import '../presentation/state/app_providers.dart';
import '../presentation/state/app_state.dart';
import '../services/ads/ad_service.dart';
import '../services/cost_stats_service.dart';
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

  static const _pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 24);
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

  void _showFeedback(
    String message, {
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (!mounted) {
      return;
    }
    final ui = SmokeUiTheme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor ?? ui.surfaceAlt,
        content: Text(
          message,
          style: TextStyle(
            color: foregroundColor ?? ui.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _runSettingAction(
    Future<void> Function() action,
    String message,
  ) async {
    await action();
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback(message);
  }

  Future<void> _handleAddRecord() async {
    await ref.read(appControllerProvider.notifier).addSmokingRecord();
    if (!mounted) {
      return;
    }
    await HapticFeedback.lightImpact();
    _showFeedback('흡연 기록을 남겼어요.');
  }

  Future<void> _handleUndoRecord() async {
    final canUndo = ref.read(appControllerProvider).records.isNotEmpty;
    if (!canUndo) {
      return;
    }

    await ref.read(appControllerProvider.notifier).undoLastRecord();
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('방금 기록을 되돌렸어요.');
  }

  Future<void> _openHomeTab() async {
    if (!mounted) {
      return;
    }
    setState(() => _tabIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    final sortedRecords = [...state.records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    List<SmokingRecord> recordsFor(RecordPeriod period) {
      final start = SmokingStatsService.startOfPeriod(period, state.now);
      return sortedRecords
          .where((record) => !record.timestamp.isBefore(start))
          .toList(growable: false);
    }

    final lastSmokingAt = SmokingStatsService.resolveLastSmokingAt(
      state.meta.lastSmokingAt,
      sortedRecords,
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

    final todayRecords = recordsFor(RecordPeriod.today);
    final monthRecords = recordsFor(RecordPeriod.month);

    final todayCount = SmokingStatsService.totalCount(todayRecords);

    final periodRecords = recordsFor(state.recordPeriod);

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

    final isCostConfigured = CostStatsService.isConfigured(state.settings);
    final todaySpend = CostStatsService.computeSpendForCount(
      cigaretteCount: todayCount,
      settings: state.settings,
    );
    final monthSpend = CostStatsService.computeSpendForRecords(
      records: monthRecords,
      settings: state.settings,
    );
    final lifetimeSpend = CostStatsService.computeLifetimeSpend(
      allRecords: state.records,
      settings: state.settings,
    );

    final periodSpend = CostStatsService.computeSpendForRecords(
      records: periodRecords,
      settings: state.settings,
    );
    final averageDailySpend = CostStatsService.computeAverageDailySpend(
      period: state.recordPeriod,
      now: state.now,
      periodRecords: periodRecords,
      settings: state.settings,
    );

    final todaySpendText = CostStatsService.formatCurrency(
      todaySpend,
      state.settings,
    );
    final monthSpendText = CostStatsService.formatCurrency(
      monthSpend,
      state.settings,
    );
    final lifetimeSpendText = CostStatsService.formatCurrency(
      lifetimeSpend,
      state.settings,
    );
    final periodSpendText = CostStatsService.formatCurrency(
      periodSpend,
      state.settings,
    );
    final averageDailySpendText = CostStatsService.formatCurrency(
      averageDailySpend,
      state.settings,
    );

    return Scaffold(
      backgroundColor: ui.background,
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
                canUndo: state.records.isNotEmpty,
                now: state.now,
                nextAlertAt: state.nextAlertAt,
                repeatEnabled: state.settings.repeatEnabled,
                hasSelectedWeekdays: state.settings.activeWeekdays.isNotEmpty,
                preAlertMinutes: state.settings.preAlertMinutes,
                use24Hour: state.settings.use24Hour,
                isCostConfigured: isCostConfigured,
                todaySpendText: todaySpendText,
                monthSpendText: monthSpendText,
                lifetimeSpendText: lifetimeSpendText,
                onAddRecord: _handleAddRecord,
                onUndoRecord: _handleUndoRecord,
                onOpenAlertSettings: () => _openAlertSettings(context),
                onOpenPricingSettings: _openCostSettingsTab,
              ),
            ),
            _scrollableTab(
              key: const PageStorageKey('tab_record'),
              child: _RecordCard(
                period: state.recordPeriod,
                records: periodRecords,
                now: state.now,
                totalCount: totalCount,
                averageIntervalText: averageIntervalText,
                maxIntervalText: maxIntervalText,
                use24Hour: state.settings.use24Hour,
                isCostConfigured: isCostConfigured,
                periodSpendText: periodSpendText,
                averageDailySpendText: averageDailySpendText,
                onPeriodChanged: controller.setRecordPeriod,
                onOpenHomeTab: _openHomeTab,
                onOpenPricingSettings: _openCostSettingsTab,
              ),
            ),
            _scrollableTab(
              key: const PageStorageKey('tab_settings'),
              child: _SettingsCard(
                darkModeEnabled: state.settings.darkModeEnabled,
                use24Hour: state.settings.use24Hour,
                ringReferenceLabel: state.settings.ringReferenceLabel,
                vibrationEnabled: state.settings.vibrationEnabled,
                soundTypeLabel: state.settings.soundTypeLabel,
                alertSummary: AlertSettingsPresenter.build(
                  AlertSettingsInput(
                    repeatEnabled: state.settings.repeatEnabled,
                    intervalMinutes: state.settings.intervalMinutes,
                    preAlertMinutes: state.settings.preAlertMinutes,
                    allowedStartMinutes: state.settings.allowedStartMinutes,
                    allowedEndMinutes: state.settings.allowedEndMinutes,
                    use24Hour: state.settings.use24Hour,
                    hasRingBaseTime: ringBaseTime != null,
                    activeWeekdayCount: state.settings.activeWeekdays.length,
                    now: state.now,
                    nextAlertAt: state.nextAlertAt,
                  ),
                ).settingsSummary,
                isCostConfigured: isCostConfigured,
                packPriceText: state.settings.packPrice > 0
                    ? CostStatsService.formatCurrency(
                        state.settings.packPrice,
                        state.settings,
                      )
                    : '미설정',
                cigarettesPerPack: state.settings.cigarettesPerPack,
                currencyLabel: state.settings.currencyLabel,
                onToggle24Hour: () => _runSettingAction(
                  controller.toggleUse24Hour,
                  state.settings.use24Hour
                      ? '12시간 표기로 바꿨어요.'
                      : '24시간 표기로 바꿨어요.',
                ),
                onToggleDarkMode: () => _runSettingAction(
                  controller.toggleDarkMode,
                  state.settings.darkModeEnabled
                      ? '라이트 모드로 전환했어요.'
                      : '다크 모드로 전환했어요.',
                ),
                onCycleRingReference: () => _runSettingAction(
                  controller.cycleRingReference,
                  '홈 원형 기준을 변경했어요.',
                ),
                onToggleVibration: () => _runSettingAction(
                  controller.toggleVibration,
                  state.settings.vibrationEnabled ? '진동을 껐어요.' : '진동을 켰어요.',
                ),
                onCycleSoundType: () => _runSettingAction(
                  controller.cycleSoundType,
                  '알림 소리를 변경했어요.',
                ),
                onOpenAlertSettings: () => _openAlertSettings(context),
                onEditPackPrice: () => _pickPackPrice(context, state),
                onEditCigarettesPerPack: () =>
                    _pickCigarettesPerPack(context, state),
                onEditCurrency: () => _pickCurrencyCode(context, state),
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
          NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: ui.surface,
              indicatorColor: Theme.of(context).brightness == Brightness.dark
                  ? ui.neutralSoft
                  : SmokeUiPalette.accentSoft,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  color: selected ? ui.textPrimary : ui.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                );
              }),
            ),
            child: NavigationBar(
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
          ),
        ],
      ),
    );
  }

  Future<void> _openCostSettingsTab() async {
    if (!mounted) {
      return;
    }
    setState(() => _tabIndex = 2);
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
          final routeUi = SmokeUiTheme.of(routeContext);
          return Scaffold(
            backgroundColor: routeUi.background,
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
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: routeUi.textPrimary,
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

                              final resolvedLastSmokingAt =
                                  SmokingStatsService.resolveLastSmokingAt(
                                    appState.meta.lastSmokingAt,
                                    appState.records,
                                  );
                              final presentation = AlertSettingsPresenter.build(
                                AlertSettingsInput(
                                  repeatEnabled:
                                      appState.settings.repeatEnabled,
                                  intervalMinutes:
                                      appState.settings.intervalMinutes,
                                  preAlertMinutes:
                                      appState.settings.preAlertMinutes,
                                  allowedStartMinutes:
                                      appState.settings.allowedStartMinutes,
                                  allowedEndMinutes:
                                      appState.settings.allowedEndMinutes,
                                  use24Hour: appState.settings.use24Hour,
                                  hasRingBaseTime:
                                      resolvedLastSmokingAt != null,
                                  activeWeekdayCount:
                                      appState.settings.activeWeekdays.length,
                                  now: appState.now,
                                  nextAlertAt: appState.nextAlertAt,
                                ),
                              );

                              return _AlertCard(
                                presentation: presentation,
                                activeWeekdays:
                                    appState.settings.activeWeekdays,
                                onToggleRepeat: () async {
                                  final ok = await controller
                                      .toggleRepeatEnabled();
                                  if (!ok) {
                                    _showFeedback(
                                      '알림 권한을 허용해야 반복 알림을 사용할 수 있어요.',
                                      backgroundColor: routeUi.criticalSoft,
                                      foregroundColor: routeUi.textPrimary,
                                    );
                                    return;
                                  }
                                  await HapticFeedback.selectionClick();
                                  _showFeedback(
                                    appState.settings.repeatEnabled
                                        ? '반복 알림을 껐어요.'
                                        : '반복 알림을 켰어요.',
                                  );
                                },
                                onPickInterval: () async {
                                  await _pickIntervalMinutes(
                                    context,
                                    initialMinutes:
                                        appState.settings.intervalMinutes,
                                    onSelected: controller.setIntervalMinutes,
                                  );
                                },
                                onSetPreAlertMinutes:
                                    controller.setPreAlertMinutes,
                                onPickRange: () =>
                                    _pickAllowedWindow(context, appState),
                                onToggleWeekday: controller.toggleWeekday,
                                onRequestPermission: () async {
                                  final ok = await controller
                                      .requestNotificationPermission();
                                  if (ok) {
                                    await HapticFeedback.selectionClick();
                                  }
                                  _showFeedback(
                                    ok
                                        ? '알림 권한이 허용되었습니다.'
                                        : '알림 권한을 허용해주세요. (시스템 설정)',
                                    backgroundColor: ok
                                        ? null
                                        : routeUi.criticalSoft,
                                    foregroundColor: routeUi.textPrimary,
                                  );
                                },
                                onSendTest: () async {
                                  final ok = await controller
                                      .sendTestNotification();
                                  if (!ok) {
                                    _showFeedback(
                                      '알림 권한이 필요합니다. (시스템 설정)',
                                      backgroundColor: routeUi.criticalSoft,
                                      foregroundColor: routeUi.textPrimary,
                                    );
                                    return;
                                  }
                                  await HapticFeedback.lightImpact();
                                  _showFeedback('테스트 알림을 보냈어요.');
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
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            String label = AlertSettingsPresenter.formatIntervalLabel(minutes);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '간격',
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$label (${minutes.toString()}분)',
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: SmokeUiPalette.accentDark,
                        inactiveTrackColor: ui.border,
                        thumbColor: SmokeUiPalette.accent,
                        overlayColor: SmokeUiPalette.accent.withValues(
                          alpha: 0.12,
                        ),
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
                          AlertSettingsPresenter.formatIntervalLabel(min),
                          style: TextStyle(
                            color: ui.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AlertSettingsPresenter.formatIntervalLabel(max),
                          style: TextStyle(
                            color: ui.textMuted,
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
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('알림 간격을 변경했어요.');
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
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('허용 시간대를 저장했어요.');
  }

  Future<void> _pickPackPrice(BuildContext context, AppState state) async {
    final initialText = state.settings.packPrice <= 0
        ? ''
        : state.settings.packPrice.toStringAsFixed(
            state.settings.packPrice % 1 == 0 ? 0 : 2,
          );

    final raw = await _showCostValueInputSheet(
      context: context,
      title: '갑당 가격',
      hintText: '예: 4500',
      helperText:
          '${AppDefaults.minPackPrice.toInt()} ~ ${AppDefaults.maxPackPrice.toInt()} 범위',
      initialText: initialText,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: (value) {
        final parsed = double.tryParse(value);
        if (parsed == null) {
          return '숫자만 입력해주세요.';
        }
        if (parsed <= 0) {
          return '0보다 큰 값을 입력해주세요.';
        }
        if (parsed < AppDefaults.minPackPrice ||
            parsed > AppDefaults.maxPackPrice) {
          return '허용 범위를 벗어났습니다.';
        }
        return null;
      },
    );

    if (raw == null || !context.mounted) {
      return;
    }
    final parsed = double.parse(raw);
    await ref.read(appControllerProvider.notifier).setPackPrice(parsed);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('갑당 가격을 저장했어요.');
  }

  Future<void> _pickCigarettesPerPack(
    BuildContext context,
    AppState state,
  ) async {
    final raw = await _showCostValueInputSheet(
      context: context,
      title: '한 갑 개비 수',
      hintText: '예: 20',
      helperText:
          '${AppDefaults.minCigarettesPerPack} ~ ${AppDefaults.maxCigarettesPerPack} 범위',
      initialText: state.settings.cigarettesPerPack.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final parsed = int.tryParse(value);
        if (parsed == null) {
          return '정수를 입력해주세요.';
        }
        if (parsed <= 0) {
          return '0보다 큰 값을 입력해주세요.';
        }
        if (parsed < AppDefaults.minCigarettesPerPack ||
            parsed > AppDefaults.maxCigarettesPerPack) {
          return '허용 범위를 벗어났습니다.';
        }
        return null;
      },
    );

    if (raw == null || !context.mounted) {
      return;
    }
    final parsed = int.parse(raw);
    await ref.read(appControllerProvider.notifier).setCigarettesPerPack(parsed);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('한 갑 개비 수를 저장했어요.');
  }

  Future<void> _pickCurrencyCode(BuildContext context, AppState state) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '통화',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...AppDefaults.currencyCodeOptions.map((code) {
                final symbol = CostStatsService.resolveCurrencySymbol(code);
                final selected = state.settings.currencyCode == code;
                return ListTile(
                  dense: true,
                  title: Text('$code ($symbol)'),
                  trailing: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: SmokeUiPalette.accentDark,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(code),
                );
              }),
            ],
          ),
        );
      },
    );

    if (picked == null || picked == state.settings.currencyCode || !mounted) {
      return;
    }
    await ref.read(appControllerProvider.notifier).setCurrencyCode(picked);
    if (!mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    _showFeedback('통화를 변경했어요.');
  }

  Future<String?> _showCostValueInputSheet({
    required BuildContext context,
    required String title,
    required String hintText,
    required String helperText,
    required String initialText,
    required List<TextInputFormatter> inputFormatters,
    required String? Function(String value) validator,
  }) async {
    final controller = TextEditingController(text: initialText);
    String? errorText;

    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('cost_input_field'),
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: inputFormatters,
                      decoration: InputDecoration(
                        hintText: hintText,
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SmokeUiPalette.accentDark,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setModalState(() {
                            errorText = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      key: const Key('cost_apply_button'),
                      text: '적용',
                      onTap: () {
                        final raw = controller.text.trim().replaceAll(',', '');
                        final validationMessage = validator(raw);
                        if (validationMessage != null) {
                          setModalState(() {
                            errorText = validationMessage;
                          });
                          return;
                        }
                        Navigator.of(context).pop(raw);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    return value;
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
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      _showFeedback('기록과 설정을 초기화했어요.');
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
    required this.canUndo,
    required this.now,
    required this.nextAlertAt,
    required this.repeatEnabled,
    required this.hasSelectedWeekdays,
    required this.preAlertMinutes,
    required this.use24Hour,
    required this.isCostConfigured,
    required this.todaySpendText,
    required this.monthSpendText,
    required this.lifetimeSpendText,
    required this.onAddRecord,
    required this.onUndoRecord,
    required this.onOpenAlertSettings,
    required this.onOpenPricingSettings,
  });

  final bool hasRingBaseTime;
  final int elapsedMinutes;
  final int intervalMinutes;
  final double ringProgress;
  final int todayCount;
  final bool canUndo;
  final DateTime now;
  final DateTime? nextAlertAt;
  final bool repeatEnabled;
  final bool hasSelectedWeekdays;
  final int preAlertMinutes;
  final bool use24Hour;
  final bool isCostConfigured;
  final String todaySpendText;
  final String monthSpendText;
  final String lifetimeSpendText;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onOpenPricingSettings;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final ringCenterFill = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1318)
        : const Color(0xFF121417);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final intervalPresentation = HomeStatusPresenter.buildIntervalStatus(
      HomeIntervalStatusInput(
        hasRingBaseTime: hasRingBaseTime,
        elapsedMinutes: elapsedMinutes,
        intervalMinutes: intervalMinutes,
      ),
    );

    final alertPresentation = HomeStatusPresenter.buildAlertStatus(
      HomeAlertStatusInput(
        hasRingBaseTime: hasRingBaseTime,
        repeatEnabled: repeatEnabled,
        hasSelectedWeekdays: hasSelectedWeekdays,
        preAlertMinutes: preAlertMinutes,
        now: now,
        nextAlertAt: nextAlertAt,
        use24Hour: use24Hour,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390 || textScale > 1.15;
        final tightHeight = MediaQuery.sizeOf(context).height < 760;
        final stackedInsights = constraints.maxWidth < 460 || textScale > 1.2;
        final stackStatusPanels =
            (constraints.maxWidth < 340 && !tightHeight) || textScale > 1.25;
        final ringSize = compact
            ? min(
                    constraints.maxWidth - (tightHeight ? 88 : 72),
                    tightHeight ? 184.0 : 196.0,
                  )
                  .clamp(
                    tightHeight ? 164.0 : 176.0,
                    tightHeight ? 184.0 : 196.0,
                  )
                  .toDouble()
            : min(constraints.maxWidth - 48, tightHeight ? 208.0 : 228.0)
                  .clamp(
                    tightHeight ? 184.0 : 188.0,
                    tightHeight ? 208.0 : 228.0,
                  )
                  .toDouble();

        final actions = compact
            ? Column(
                children: [
                  PrimaryButton(
                    text: '지금 흡연 기록',
                    icon: Icons.add_rounded,
                    color: SmokeUiPalette.accent,
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    onTap: () async {
                      await onAddRecord();
                    },
                  ),
                  const SizedBox(height: SmokeUiSpacing.sm),
                  SecondaryButton(
                    text: '되돌리기',
                    icon: Icons.undo_rounded,
                    foregroundColor: ui.textSecondary,
                    backgroundColor: ui.surfaceAlt,
                    borderColor: ui.border,
                    onTap: canUndo
                        ? () async {
                            await onUndoRecord();
                          }
                        : null,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PrimaryButton(
                      text: '지금 흡연 기록',
                      icon: Icons.add_rounded,
                      color: SmokeUiPalette.accent,
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      onTap: () async {
                        await onAddRecord();
                      },
                    ),
                  ),
                  const SizedBox(width: SmokeUiSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SecondaryButton(
                      text: '되돌리기',
                      icon: Icons.undo_rounded,
                      foregroundColor: ui.textSecondary,
                      backgroundColor: ui.surfaceAlt,
                      borderColor: ui.border,
                      onTap: canUndo
                          ? () async {
                              await onUndoRecord();
                            }
                          : null,
                    ),
                  ),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SurfaceCard(
              color: ui.surface,
              strokeColor: ui.border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              padding: EdgeInsets.all(tightHeight ? 14 : SmokeUiSpacing.md),
              cornerRadius: SmokeUiRadius.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '흡연 타이머',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ui.textPrimary,
                                fontFamily: 'Sora',
                                fontSize: tightHeight ? 28 : 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: SmokeUiSpacing.xxs),
                            Text(
                              '지금 상태를 빠르게 확인하고 바로 기록하세요.',
                              style: TextStyle(
                                color: ui.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: SmokeUiSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: SecondaryButton(
                          text: '알림 설정',
                          icon: Icons.notifications_none_rounded,
                          height: 40,
                          foregroundColor: ui.textPrimary,
                          backgroundColor: ui.surfaceAlt,
                          borderColor: ui.border,
                          onTap: () async {
                            await onOpenAlertSettings();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tightHeight ? 12 : SmokeUiSpacing.md),
                  Center(
                    child: SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RingGauge(
                            size: ringSize,
                            strokeWidth: 12,
                            trackColor: ui.ringTrack,
                            sweepAngle: ringProgress * 2 * pi,
                            value: ' ',
                            label: ' ',
                            valueStyle: const TextStyle(
                              color: Colors.transparent,
                              fontSize: 1,
                            ),
                            labelStyle: const TextStyle(
                              color: Colors.transparent,
                              fontSize: 1,
                            ),
                          ),
                          Container(
                            width: ringSize * 0.66,
                            height: ringSize * 0.66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ringCenterFill,
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    elapsedMinutes.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontFamily: 'Sora',
                                      fontSize: 52,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '분 경과',
                                    style: TextStyle(
                                      color: Color(0xFFD0D7E2),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: tightHeight ? 8 : SmokeUiSpacing.sm),
                  Center(
                    child: Text(
                      hasRingBaseTime
                          ? '마지막 기록 후 ${elapsedMinutes.toString()}분 지났어요.'
                          : '첫 기록을 남기면 타이머가 시작돼요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: tightHeight ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: tightHeight ? 12 : SmokeUiSpacing.md),
                  if (compact) ...[
                    actions,
                    SizedBox(height: tightHeight ? 12 : SmokeUiSpacing.md),
                    _HomeStatusPanel(
                      label: '지금 상태',
                      presentation: intervalPresentation,
                    ),
                    const SizedBox(height: SmokeUiSpacing.sm),
                    _HomeStatusPanel(
                      label: '다음 알림',
                      presentation: alertPresentation,
                    ),
                  ] else if (stackStatusPanels) ...[
                    _HomeStatusPanel(
                      label: '지금 상태',
                      presentation: intervalPresentation,
                    ),
                    const SizedBox(height: SmokeUiSpacing.sm),
                    _HomeStatusPanel(
                      label: '다음 알림',
                      presentation: alertPresentation,
                    ),
                    SizedBox(height: tightHeight ? 12 : SmokeUiSpacing.md),
                    actions,
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _HomeStatusPanel(
                            label: '지금 상태',
                            presentation: intervalPresentation,
                          ),
                        ),
                        const SizedBox(width: SmokeUiSpacing.sm),
                        Expanded(
                          child: _HomeStatusPanel(
                            label: '다음 알림',
                            presentation: alertPresentation,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tightHeight ? 12 : SmokeUiSpacing.md),
                    actions,
                  ],
                ],
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.lg),
            const SectionLabel(text: '오늘 요약'),
            const SizedBox(height: SmokeUiSpacing.xs),
            if (stackedInsights) ...[
              _HomeTodaySummaryCard(todayCount: todayCount),
              const SizedBox(height: SmokeUiSpacing.sm),
              _HomeCostSummaryCard(
                isCostConfigured: isCostConfigured,
                todaySpendText: todaySpendText,
                monthSpendText: monthSpendText,
                lifetimeSpendText: lifetimeSpendText,
                onOpenPricingSettings: onOpenPricingSettings,
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HomeTodaySummaryCard(todayCount: todayCount),
                  ),
                  const SizedBox(width: SmokeUiSpacing.sm),
                  Expanded(
                    child: _HomeCostSummaryCard(
                      isCostConfigured: isCostConfigured,
                      todaySpendText: todaySpendText,
                      monthSpendText: monthSpendText,
                      lifetimeSpendText: lifetimeSpendText,
                      onOpenPricingSettings: onOpenPricingSettings,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HomeStatusPanel extends StatelessWidget {
  const _HomeStatusPanel({required this.label, required this.presentation});

  final String label;
  final HomeStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final tonePalette = _StatusTonePalette.fromTone(presentation.tone);
    return SurfaceCard(
      color: ui.surfaceAlt,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(10),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: SmokeUiSpacing.xs),
              Flexible(
                child: StatusChip(
                  text: presentation.chipText,
                  icon: presentation.icon,
                  foregroundColor: tonePalette.foregroundColor,
                  backgroundColor: tonePalette.backgroundColor,
                  borderColor: tonePalette.borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            presentation.title,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            presentation.detail,
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTonePalette {
  const _StatusTonePalette({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  /// Maps semantic status tone to the shared chip color system.
  factory _StatusTonePalette.fromTone(HomeStatusTone tone) {
    switch (tone) {
      case HomeStatusTone.info:
        return const _StatusTonePalette(
          foregroundColor: SmokeUiPalette.info,
          backgroundColor: SmokeUiPalette.infoSoft,
          borderColor: Color(0xFF9BD9E8),
        );
      case HomeStatusTone.warning:
        return const _StatusTonePalette(
          foregroundColor: SmokeUiPalette.warning,
          backgroundColor: SmokeUiPalette.warningSoft,
          borderColor: Color(0xFFF3C58F),
        );
      case HomeStatusTone.success:
        return const _StatusTonePalette(
          foregroundColor: SmokeUiPalette.mint,
          backgroundColor: SmokeUiPalette.mintSoft,
          borderColor: Color(0xFF94E3CF),
        );
      case HomeStatusTone.risk:
        return const _StatusTonePalette(
          foregroundColor: SmokeUiPalette.risk,
          backgroundColor: SmokeUiPalette.riskSoft,
          borderColor: Color(0xFFF4B6B3),
        );
    }
  }
}

class _HomeTodaySummaryCard extends StatelessWidget {
  const _HomeTodaySummaryCard({required this.todayCount});

  final int todayCount;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(SmokeUiSpacing.sm),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '오늘 흡연',
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.smoking_rooms_rounded,
                size: 18,
                color: ui.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: SmokeUiSpacing.xs),
          Text(
            '${todayCount.toString()}개비',
            style: TextStyle(
              color: ui.textPrimary,
              fontFamily: 'Sora',
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xxs),
          Text(
            todayCount == 0 ? '아직 오늘 기록이 없어요.' : '오늘 남긴 기록이 바로 반영됐어요.',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCostSummaryCard extends StatelessWidget {
  const _HomeCostSummaryCard({
    required this.isCostConfigured,
    required this.todaySpendText,
    required this.monthSpendText,
    required this.lifetimeSpendText,
    required this.onOpenPricingSettings,
  });

  final bool isCostConfigured;
  final String todaySpendText;
  final String monthSpendText;
  final String lifetimeSpendText;
  final Future<void> Function() onOpenPricingSettings;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(SmokeUiSpacing.sm),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지출 요약',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xs),
          if (!isCostConfigured) ...[
            Text(
              '가격 정보를 설정하면 지출을 계산할 수 있어요.',
              key: const Key('cost_empty_state_text'),
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                key: const Key('set_pricing_cta'),
                text: '가격 설정',
                icon: Icons.toll_outlined,
                foregroundColor: ui.textPrimary,
                backgroundColor: ui.surfaceAlt,
                borderColor: ui.border,
                onTap: () async {
                  await onOpenPricingSettings();
                },
              ),
            ),
          ] else ...[
            _SpendMetric(label: '오늘 지출', value: todaySpendText),
            const SizedBox(height: SmokeUiSpacing.xs),
            _SpendMetric(label: '이번 달 지출', value: monthSpendText),
            const SizedBox(height: SmokeUiSpacing.xs),
            _SpendMetric(label: '누적 지출', value: lifetimeSpendText),
          ],
        ],
      ),
    );
  }
}

class _SpendMetric extends StatelessWidget {
  const _SpendMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      cornerRadius: 10,
      strokeColor: ui.border,
      color: ui.surfaceAlt,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.period,
    required this.records,
    required this.now,
    required this.totalCount,
    required this.averageIntervalText,
    required this.maxIntervalText,
    required this.use24Hour,
    required this.isCostConfigured,
    required this.periodSpendText,
    required this.averageDailySpendText,
    required this.onPeriodChanged,
    required this.onOpenHomeTab,
    required this.onOpenPricingSettings,
  });

  final RecordPeriod period;
  final List<SmokingRecord> records;
  final DateTime now;
  final int totalCount;
  final String averageIntervalText;
  final String maxIntervalText;
  final bool use24Hour;
  final bool isCostConfigured;
  final String periodSpendText;
  final String averageDailySpendText;
  final ValueChanged<RecordPeriod> onPeriodChanged;
  final Future<void> Function() onOpenHomeTab;
  final Future<void> Function() onOpenPricingSettings;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackedSummaryCards =
            constraints.maxWidth < 380 || textScale > 1.15;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기록',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '기간별 기록 흐름과 간격 변화를 빠르게 확인합니다.',
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              color: ui.surface,
              strokeColor: ui.border,
              padding: const EdgeInsets.all(SmokeUiSpacing.xs),
              cornerRadius: SmokeUiRadius.md,
              child: SizedBox(
                height: 46,
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
            ),
            const SizedBox(height: 16),
            _SummaryItem(
              label: '총 개비',
              value: '$totalCount개비',
              detail: '선택한 기간 동안 남긴 총 기록 수예요.',
              valueFontSize: 28,
              emphasized: true,
            ),
            const SizedBox(height: 8),
            if (stackedSummaryCards) ...[
              _SummaryItem(
                label: '평균 간격',
                value: averageIntervalText,
                detail: '기록 사이 평균 간격',
                valueFontSize: 20,
              ),
              const SizedBox(height: 8),
              _SummaryItem(
                label: '최장 간격',
                value: maxIntervalText,
                detail: '가장 길었던 간격',
                valueFontSize: 20,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: '평균 간격',
                      value: averageIntervalText,
                      detail: '기록 사이 평균 간격',
                      valueFontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryItem(
                      label: '최장 간격',
                      value: maxIntervalText,
                      detail: '가장 길었던 간격',
                      valueFontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SurfaceCard(
              color: ui.surface,
              strokeColor: ui.border,
              padding: const EdgeInsets.all(12),
              cornerRadius: SmokeUiRadius.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(text: '비용 인사이트'),
                  const SizedBox(height: 10),
                  if (!isCostConfigured) ...[
                    Text(
                      '가격 정보를 설정하면 지출 통계를 볼 수 있어요.',
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        text: '가격 설정',
                        icon: Icons.toll_outlined,
                        foregroundColor: ui.textPrimary,
                        backgroundColor: ui.surfaceAlt,
                        borderColor: ui.border,
                        onTap: () async {
                          await onOpenPricingSettings();
                        },
                      ),
                    ),
                  ] else ...[
                    if (stackedSummaryCards) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '흡연 개비',
                          value: '$totalCount개비',
                          detail: '선택한 기간 합계',
                          valueFontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '예상 지출',
                          value: periodSpendText,
                          detail: '선택한 기간 기준',
                          valueFontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '일 평균',
                          value: averageDailySpendText,
                          detail: '하루 평균 예상 지출',
                          valueFontSize: 16,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: '흡연 개비',
                              value: '$totalCount개비',
                              detail: '선택한 기간 합계',
                              valueFontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryItem(
                              label: '예상 지출',
                              value: periodSpendText,
                              detail: '선택한 기간 기준',
                              valueFontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryItem(
                              label: '일 평균',
                              value: averageDailySpendText,
                              detail: '하루 평균 예상 지출',
                              valueFontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              cornerRadius: 16,
              color: ui.surface,
              strokeColor: ui.border,
              child: _RecordList(
                now: now,
                records: records,
                use24Hour: use24Hour,
                onOpenHomeTab: onOpenHomeTab,
              ),
            ),
          ],
        );
      },
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
    final ui = SmokeUiTheme.of(context);
    return Material(
      color: selected ? SmokeUiPalette.accentSoft : ui.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? SmokeUiPalette.accentDark : ui.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? SmokeUiPalette.accentDark : ui.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
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
    this.detail,
    required this.valueFontSize,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String? detail;
  final double valueFontSize;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      cornerRadius: 12,
      strokeColor: ui.border,
      color: emphasized ? ui.surfaceAlt : ui.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.now,
    required this.records,
    required this.use24Hour,
    required this.onOpenHomeTab,
  });

  final DateTime now;
  final List<SmokingRecord> records;
  final bool use24Hour;
  final Future<void> Function() onOpenHomeTab;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.receipt_long_outlined, size: 26, color: ui.textMuted),
            const SizedBox(height: 10),
            Text(
              '기록이 없습니다',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Home 탭에서 지금 흡연 기록을 누르면 여기에 쌓여요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              text: 'Home로 이동',
              icon: Icons.timer_outlined,
              foregroundColor: ui.textPrimary,
              backgroundColor: ui.surfaceAlt,
              borderColor: ui.border,
              onTap: () async {
                await onOpenHomeTab();
              },
            ),
          ],
        ),
      );
    }

    const maxVisible = 20;
    final visibleCount = min(records.length, maxVisible);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Text(
            '최근 기록',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...List.generate(visibleCount, (index) {
          final record = records[index];
          final time = TimeFormatter.formatDayAwareClock(
            now,
            record.timestamp,
            use24Hour: use24Hour,
          );

          return _RecordListRow(
            time: time,
            amount: '${record.count}개비',
            sameDay: DateUtils.isSameDay(now, record.timestamp),
            withTopBorder: index > 0,
          );
        }),
      ],
    );
  }
}

class _RecordListRow extends StatelessWidget {
  const _RecordListRow({
    required this.time,
    required this.amount,
    required this.sameDay,
    required this.withTopBorder,
  });

  final String time;
  final String amount;
  final bool sameDay;
  final bool withTopBorder;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: withTopBorder
            ? Border(top: BorderSide(color: ui.border, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sameDay ? '오늘 기록' : '이전 기록',
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ui.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ui.border),
            ),
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.presentation,
    required this.activeWeekdays,
    required this.onToggleRepeat,
    required this.onPickInterval,
    required this.onSetPreAlertMinutes,
    required this.onPickRange,
    required this.onToggleWeekday,
    required this.onRequestPermission,
    required this.onSendTest,
  });

  final AlertSettingsPresentation presentation;
  final Set<int> activeWeekdays;
  final Future<void> Function() onToggleRepeat;
  final Future<void> Function() onPickInterval;
  final Future<void> Function(int minutes) onSetPreAlertMinutes;
  final Future<void> Function() onPickRange;
  final Future<void> Function(int weekday) onToggleWeekday;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 400 || textScale > 1.15;
    final repeatTonePalette = _AlertTonePalette.fromTone(
      presentation.repeatChipTone,
    );
    final scheduleTonePalette = _AlertTonePalette.fromTone(
      presentation.scheduleChipTone,
    );
    final weekdayTonePalette = _AlertTonePalette.fromTone(
      presentation.weekdayTone,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 설정',
          style: TextStyle(
            color: ui.textPrimary,
            fontFamily: 'Sora',
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '흡연 루틴에 맞는 로컬 알림 스케줄을 설정합니다.',
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          color: ui.surfaceAlt,
          strokeColor: ui.border,
          padding: const EdgeInsets.all(14),
          cornerRadius: SmokeUiRadius.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    text: presentation.repeatChipText,
                    icon: presentation.repeatChipIcon,
                    foregroundColor: repeatTonePalette.foregroundColor,
                    backgroundColor: repeatTonePalette.backgroundColor,
                    borderColor: repeatTonePalette.borderColor,
                  ),
                  StatusChip(
                    text: presentation.scheduleChipText,
                    icon: Icons.schedule_rounded,
                    foregroundColor: scheduleTonePalette.foregroundColor,
                    backgroundColor: scheduleTonePalette.backgroundColor,
                    borderColor: scheduleTonePalette.borderColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionLabel(text: '다음 일정'),
              const SizedBox(height: 4),
              Text(
                presentation.nextAlertPreviewText,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (compact) ...[
                _AlertOverviewMetric(
                  label: '간격',
                  value: presentation.intervalLabel,
                ),
                const SizedBox(height: 8),
                _AlertOverviewMetric(
                  label: '시간대',
                  value: presentation.rangeText,
                ),
                const SizedBox(height: 8),
                _AlertOverviewMetric(
                  label: '활성 요일',
                  value: presentation.weekdayCountText,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _AlertOverviewMetric(
                        label: '간격',
                        value: presentation.intervalLabel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AlertOverviewMetric(
                        label: '시간대',
                        value: presentation.rangeText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AlertOverviewMetric(
                        label: '활성 요일',
                        value: presentation.weekdayCountText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '기본'),
        const SizedBox(height: 8),
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
                labelStyle: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                trailing: TogglePill(isOn: presentation.repeatEnabled),
                onTap: onToggleRepeat,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '알림 권한',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
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
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: presentation.intervalLabel,
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
                label: presentation.nextAlertRowLabel,
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: presentation.nextAlertPreviewText,
                valueMaxLines: 2,
                valueStyle: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                withTopBorder: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '시간과 요일'),
        const SizedBox(height: 8),
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
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: presentation.rangeText,
                showChevron: true,
                onTap: onPickRange,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ui.border, width: 1)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '미리 알림',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          presentation.preAlertValueText,
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: SmokeUiPalette.accent,
                        inactiveTrackColor: ui.border,
                        thumbColor: SmokeUiPalette.accent,
                        overlayColor: SmokeUiPalette.accent.withValues(
                          alpha: 0.14,
                        ),
                      ),
                      child: Slider(
                        key: const Key('pre_alert_slider'),
                        min: AppDefaults.minPreAlertMinutes.toDouble(),
                        max: AppDefaults.maxPreAlertMinutes.toDouble(),
                        divisions:
                            AppDefaults.maxPreAlertMinutes -
                            AppDefaults.minPreAlertMinutes,
                        value: presentation.preAlertMinutes.toDouble().clamp(
                          AppDefaults.minPreAlertMinutes.toDouble(),
                          AppDefaults.maxPreAlertMinutes.toDouble(),
                        ),
                        label: '${presentation.preAlertMinutes}분',
                        onChanged: (value) {
                          onSetPreAlertMinutes(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '요일',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        StatusChip(
                          text: presentation.weekdayCountText,
                          icon: Icons.calendar_month_outlined,
                          foregroundColor: weekdayTonePalette.foregroundColor,
                          backgroundColor: weekdayTonePalette.backgroundColor,
                          borderColor: weekdayTonePalette.borderColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: Step1Screen._weekdayLabels.entries
                          .map(
                            (entry) => GestureDetector(
                              onTap: () async {
                                await onToggleWeekday(entry.key);
                              },
                              child: SizedBox(
                                width: 38,
                                child: DayChip(
                                  text: entry.value,
                                  active: activeWeekdays.contains(entry.key),
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (presentation.showWeekdayHint) ...[
                      const SizedBox(height: 8),
                      Text(
                        '반복할 요일을 하나 이상 선택해야 다음 알림을 만들 수 있어요.',
                        style: TextStyle(
                          color: ui.textMuted,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '테스트'),
        const SizedBox(height: 8),
        if (compact) ...[
          SecondaryButton(
            text: '알림 권한',
            icon: Icons.shield_outlined,
            foregroundColor: ui.textPrimary,
            backgroundColor: ui.surfaceAlt,
            borderColor: ui.border,
            onTap: () async {
              await onRequestPermission();
            },
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            text: '테스트 알림 보내기',
            icon: Icons.notifications_active_rounded,
            color: SmokeUiPalette.accent,
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            onTap: () async {
              await onSendTest();
            },
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: '알림 권한',
                  icon: Icons.shield_outlined,
                  foregroundColor: ui.textPrimary,
                  backgroundColor: ui.surfaceAlt,
                  borderColor: ui.border,
                  onTap: () async {
                    await onRequestPermission();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  text: '테스트 알림 보내기',
                  icon: Icons.notifications_active_rounded,
                  color: SmokeUiPalette.accent,
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  onTap: () async {
                    await onSendTest();
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '알림이 예상과 다르면 권한, 요일, 허용 시간대 순서로 확인해 주세요.',
          style: TextStyle(
            color: ui.textMuted,
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AlertTonePalette {
  const _AlertTonePalette({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  /// Maps semantic alert tones to the shared settings chip palette.
  factory _AlertTonePalette.fromTone(AlertSettingsTone tone) {
    switch (tone) {
      case AlertSettingsTone.info:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.info,
          backgroundColor: SmokeUiPalette.infoSoft,
          borderColor: Color(0xFF9BD9E8),
        );
      case AlertSettingsTone.warning:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.warning,
          backgroundColor: SmokeUiPalette.warningSoft,
          borderColor: Color(0xFFF3C58F),
        );
      case AlertSettingsTone.success:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.mint,
          backgroundColor: SmokeUiPalette.mintSoft,
          borderColor: Color(0xFF94E3CF),
        );
      case AlertSettingsTone.risk:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.risk,
          backgroundColor: SmokeUiPalette.riskSoft,
          borderColor: Color(0xFFF4B6B3),
        );
    }
  }
}

class _AlertOverviewMetric extends StatelessWidget {
  const _AlertOverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      cornerRadius: SmokeUiRadius.sm,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ui.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.darkModeEnabled,
    required this.use24Hour,
    required this.ringReferenceLabel,
    required this.vibrationEnabled,
    required this.soundTypeLabel,
    required this.alertSummary,
    required this.isCostConfigured,
    required this.packPriceText,
    required this.cigarettesPerPack,
    required this.currencyLabel,
    required this.onToggleDarkMode,
    required this.onToggle24Hour,
    required this.onCycleRingReference,
    required this.onToggleVibration,
    required this.onCycleSoundType,
    required this.onOpenAlertSettings,
    required this.onEditPackPrice,
    required this.onEditCigarettesPerPack,
    required this.onEditCurrency,
    required this.onResetData,
  });

  final bool darkModeEnabled;
  final bool use24Hour;
  final String ringReferenceLabel;
  final bool vibrationEnabled;
  final String soundTypeLabel;
  final String alertSummary;
  final bool isCostConfigured;
  final String packPriceText;
  final int cigarettesPerPack;
  final String currencyLabel;
  final Future<void> Function() onToggleDarkMode;
  final Future<void> Function() onToggle24Hour;
  final Future<void> Function() onCycleRingReference;
  final Future<void> Function() onToggleVibration;
  final Future<void> Function() onCycleSoundType;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onEditPackPrice;
  final Future<void> Function() onEditCigarettesPerPack;
  final Future<void> Function() onEditCurrency;
  final Future<void> Function() onResetData;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: ui.textPrimary,
            fontFamily: 'Sora',
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '알림, 비용, 표시 방식을 섹션별로 관리합니다.',
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '알림'),
        const SizedBox(height: 8),
        SurfaceCard(
          child: _SettingRow(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            label: '알림 설정',
            labelStyle: TextStyle(
              color: ui.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            value: alertSummary,
            showChevron: true,
            onTap: onOpenAlertSettings,
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '비용'),
        const SizedBox(height: 8),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingRow(
                rowKey: const Key('cost_pack_price_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '갑당 가격',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: packPriceText,
                showChevron: true,
                onTap: onEditPackPrice,
              ),
              _SettingRow(
                rowKey: const Key('cost_cigarettes_per_pack_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '한 갑 개비 수',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: '${cigarettesPerPack.toString()}개비',
                withTopBorder: true,
                showChevron: true,
                onTap: onEditCigarettesPerPack,
              ),
              _SettingRow(
                rowKey: const Key('cost_currency_row'),
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '통화',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: currencyLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onEditCurrency,
              ),
              if (!isCostConfigured)
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: Text(
                    '가격 정보를 설정하면 지출을 계산할 수 있어요.',
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '표시'),
        const SizedBox(height: 8),
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
                labelStyle: TextStyle(
                  color: ui.textPrimary,
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
                label: l10n.darkModeLabel,
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                withTopBorder: true,
                trailing: TogglePill(isOn: darkModeEnabled),
                onTap: onToggleDarkMode,
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '홈 원형 기준',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                value: ringReferenceLabel,
                withTopBorder: true,
                showChevron: true,
                onTap: onCycleRingReference,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionLabel(text: '피드백'),
        const SizedBox(height: 8),
        SurfaceCard(
          child: Column(
            children: [
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: '진동',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
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
                labelStyle: TextStyle(
                  color: ui.textSecondary,
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
        const SectionLabel(text: '데이터'),
        const SizedBox(height: 8),
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
                label: '데이터 초기화',
                labelStyle: const TextStyle(
                  color: Color(0xFFD95B57),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                onTap: onResetData,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  '기록과 설정을 모두 지우는 작업입니다.',
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    this.rowKey,
    required this.height,
    required this.padding,
    required this.label,
    required this.labelStyle,
    this.value,
    this.valueMaxLines = 1,
    this.valueStyle,
    this.trailing,
    this.withTopBorder = false,
    this.showChevron = false,
    this.onTap,
  });

  final Key? rowKey;
  final double height;
  final EdgeInsetsGeometry padding;
  final String label;
  final TextStyle labelStyle;
  final String? value;
  final int valueMaxLines;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool withTopBorder;
  final bool showChevron;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final trailingWidgets = trailing == null
        ? const <Widget>[]
        : <Widget>[trailing!];

    final content = Container(
      key: rowKey,
      constraints: BoxConstraints(minHeight: height),
      padding: padding,
      decoration: BoxDecoration(
        border: withTopBorder
            ? Border(top: BorderSide(color: ui.border, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ),
          if (value != null)
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                value!,
                maxLines: valueMaxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style:
                    valueStyle ??
                    TextStyle(
                      color: ui.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          if (value != null && showChevron) const SizedBox(width: 8),
          if (showChevron)
            Icon(Icons.chevron_right_rounded, size: 14, color: ui.textMuted),
          ...trailingWidgets,
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onTap!();
        },
        child: content,
      ),
    );
  }
}
