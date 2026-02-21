import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_defaults.dart';
import '../domain/models/record_period.dart';
import '../domain/models/smoking_record.dart';
import '../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
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
    final monthRecords = SmokingStatsService.recordsForPeriod(
      state.records,
      RecordPeriod.month,
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
                nextAlertText: nextAlertText,
                isCostConfigured: isCostConfigured,
                todaySpendText: todaySpendText,
                monthSpendText: monthSpendText,
                lifetimeSpendText: lifetimeSpendText,
                onAddRecord: controller.addSmokingRecord,
                onUndoRecord: controller.undoLastRecord,
                onOpenAlertSettings: () => _openAlertSettings(context),
                onOpenPricingSettings: _openCostSettingsTab,
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
                isCostConfigured: isCostConfigured,
                periodSpendText: periodSpendText,
                averageDailySpendText: averageDailySpendText,
                onPeriodChanged: controller.setRecordPeriod,
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
                alertSummary: state.settings.repeatEnabled
                    ? '켜짐 · ${_formatIntervalLabel(state.settings.intervalMinutes)}'
                    : '꺼짐',
                isCostConfigured: isCostConfigured,
                packPriceText: state.settings.packPrice > 0
                    ? CostStatsService.formatCurrency(
                        state.settings.packPrice,
                        state.settings,
                      )
                    : '미설정',
                cigarettesPerPack: state.settings.cigarettesPerPack,
                currencyLabel: state.settings.currencyLabel,
                onToggle24Hour: controller.toggleUse24Hour,
                onToggleDarkMode: controller.toggleDarkMode,
                onCycleRingReference: controller.cycleRingReference,
                onToggleVibration: controller.toggleVibration,
                onCycleSoundType: controller.cycleSoundType,
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
                                onSetPreAlertMinutes:
                                    controller.setPreAlertMinutes,
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
      backgroundColor: SmokeUiTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final ui = SmokeUiTheme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            String label = _formatIntervalLabel(minutes);
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
                          _formatIntervalLabel(min),
                          style: TextStyle(
                            color: ui.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatIntervalLabel(max),
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
  final String nextAlertText;
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

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackedTodayActions = textScale > 1.25;
    final stackedSpendMetrics = textScale > 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '흡연 타이머',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontFamily: 'Sora',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: ui.surface,
              borderRadius: BorderRadius.circular(10),
              child: IconButton(
                tooltip: '알림 설정',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
                onPressed: () async {
                  await onOpenAlertSettings();
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '마지막 기록 기준 경과/남은 시간을 표시합니다.',
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          color: ui.surface,
          strokeColor: ui.border,
          padding: const EdgeInsets.all(16),
          cornerRadius: 16,
          child: Column(
            children: [
              SizedBox(
                height: 262,
                child: Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RingGauge(
                          size: 250,
                          strokeWidth: 10,
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
                          width: 162,
                          height: 162,
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
                                  ringValueMinutes.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFFF8FAFC),
                                    fontFamily: 'Sora',
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  ringLabel,
                                  style: const TextStyle(
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
              ),
              Text(
                '설정 간격 ${intervalMinutes.toString()}분',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: '지금 흡연 기록',
                color: SmokeUiPalette.accent,
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                onTap: () async {
                  await onAddRecord();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          cornerRadius: 16,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '오늘 흡연',
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.smoking_rooms_rounded,
                    size: 18,
                    color: ui.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (stackedTodayActions) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${todayCount.toString()}개비',
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontFamily: 'Sora',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        text: '되돌리기',
                        foreground: ui.textSecondary,
                        background: ui.neutralSoft,
                        borderColor: ui.border,
                        onTap: onUndoRecord,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        text: '+1 추가',
                        foreground: Colors.white,
                        background: const Color(0xFF1D4ED8),
                        onTap: onAddRecord,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '${todayCount.toString()}개비',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ui.textPrimary,
                          fontFamily: 'Sora',
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      text: '되돌리기',
                      foreground: ui.textSecondary,
                      background: ui.neutralSoft,
                      borderColor: ui.border,
                      onTap: onUndoRecord,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      text: '+1 추가',
                      foreground: Colors.white,
                      background: const Color(0xFF1D4ED8),
                      onTap: onAddRecord,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          cornerRadius: 16,
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
              const SizedBox(height: 10),
              if (!isCostConfigured) ...[
                Text(
                  '가격 정보를 설정하면 지출을 계산할 수 있어요.',
                  key: Key('cost_empty_state_text'),
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    key: const Key('set_pricing_cta'),
                    onTap: () async {
                      await onOpenPricingSettings();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ui.neutralSoft,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: ui.border),
                      ),
                      child: Text(
                        '가격 설정',
                        style: TextStyle(
                          color: ui.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                if (stackedSpendMetrics) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _SpendMetric(label: '오늘 지출', value: todaySpendText),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _SpendMetric(
                      label: '이번 달 지출',
                      value: monthSpendText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _SpendMetric(
                      label: '누적 지출',
                      value: lifetimeSpendText,
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _SpendMetric(
                          label: '오늘 지출',
                          value: todaySpendText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SpendMetric(
                          label: '이번 달 지출',
                          value: monthSpendText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SpendMetric(
                          label: '누적 지출',
                          value: lifetimeSpendText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          nextAlertText,
          style: TextStyle(
            color: ui.textSecondary,
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () async {
          await onTap();
        },
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
      color: ui.surface,
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
    required this.totalCount,
    required this.averageIntervalText,
    required this.maxIntervalText,
    required this.use24Hour,
    required this.isCostConfigured,
    required this.periodSpendText,
    required this.averageDailySpendText,
    required this.onPeriodChanged,
    required this.onOpenPricingSettings,
  });

  final RecordPeriod period;
  final List<SmokingRecord> records;
  final int totalCount;
  final String averageIntervalText;
  final String maxIntervalText;
  final bool use24Hour;
  final bool isCostConfigured;
  final String periodSpendText;
  final String averageDailySpendText;
  final ValueChanged<RecordPeriod> onPeriodChanged;
  final Future<void> Function() onOpenPricingSettings;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackedSummaryCards =
            constraints.maxWidth < 340 || textScale > 1.25;
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
            if (stackedSummaryCards) ...[
              SizedBox(
                width: double.infinity,
                child: _SummaryItem(
                  label: '총 개비',
                  value: '$totalCount',
                  valueFontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _SummaryItem(
                  label: '평균 간격',
                  value: averageIntervalText,
                  valueFontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _SummaryItem(
                  label: '최장 간격',
                  value: maxIntervalText,
                  valueFontSize: 20,
                ),
              ),
            ] else ...[
              Row(
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
            ],
            const SizedBox(height: 16),
            SurfaceCard(
              color: ui.surface,
              strokeColor: ui.border,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비용 인사이트',
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          await onOpenPricingSettings();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ui.neutralSoft,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: ui.border),
                          ),
                          child: Text(
                            '가격 설정',
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (stackedSummaryCards) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '흡연 개비',
                          value: '$totalCount',
                          valueFontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '예상 지출',
                          value: periodSpendText,
                          valueFontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _SummaryItem(
                          label: '일 평균',
                          value: averageDailySpendText,
                          valueFontSize: 16,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryItem(
                              label: '흡연 개비',
                              value: '$totalCount',
                              valueFontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryItem(
                              label: '예상 지출',
                              value: periodSpendText,
                              valueFontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryItem(
                              label: '일 평균',
                              value: averageDailySpendText,
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
              child: _RecordList(records: records, use24Hour: use24Hour),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SmokeUiPalette.accentDark : ui.neutralSoft,
          borderRadius: BorderRadius.circular(11),
          border: selected ? null : Border.all(color: ui.border),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : ui.textSecondary,
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
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      cornerRadius: 12,
      strokeColor: ui.border,
      color: ui.surface,
      padding: const EdgeInsets.all(10),
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
        ],
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
    final ui = SmokeUiTheme.of(context);
    if (records.isEmpty) {
      return SizedBox(
        height: 144,
        child: Center(
          child: Text(
            '기록이 없습니다',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    const maxVisible = 20;
    final visibleCount = min(records.length, maxVisible);

    return Column(
      children: List.generate(visibleCount, (index) {
        final record = records[index];
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
    required this.repeatEnabled,
    required this.intervalMinutes,
    required this.preAlertMinutes,
    required this.rangeText,
    required this.nextAlertPreviewText,
    required this.activeWeekdays,
    required this.onToggleRepeat,
    required this.onPickInterval,
    required this.onSetPreAlertMinutes,
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
  final Future<void> Function(int minutes) onSetPreAlertMinutes;
  final Future<void> Function() onPickRange;
  final Future<void> Function(int weekday) onToggleWeekday;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
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
                value: '${intervalMinutes.toString()}분',
                withTopBorder: true,
                showChevron: true,
                onTap: onPickInterval,
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
                          '${preAlertMinutes.toString()}분 전',
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
                        value: preAlertMinutes.toDouble().clamp(
                          AppDefaults.minPreAlertMinutes.toDouble(),
                          AppDefaults.maxPreAlertMinutes.toDouble(),
                        ),
                        label: '${preAlertMinutes.toString()}분',
                        onChanged: (value) {
                          onSetPreAlertMinutes(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _SettingRow(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                label: preAlertMinutes > 0 ? '미리 알림' : '다음 알림',
                labelStyle: TextStyle(
                  color: ui.textSecondary,
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
                labelStyle: TextStyle(
                  color: ui.textSecondary,
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
                    Text(
                      '요일',
                      style: TextStyle(
                        color: ui.textSecondary,
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
        const SizedBox(height: 16),
        Text(
          '알림 권한이 꺼져 있으면 시스템 설정에서 켜주세요.',
          style: TextStyle(
            color: ui.textMuted,
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
        const SizedBox(height: 16),
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
        SurfaceCard(
          child: _SettingRow(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            label: '데이터 초기화',
            labelStyle: const TextStyle(
              color: Color(0xFFD95B57),
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
    this.rowKey,
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

  final Key? rowKey;
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
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
