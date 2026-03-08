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
import 'privacy_policy_screen.dart';
import '../services/ads/ad_service.dart';
import '../services/cost_stats_service.dart';
import '../services/smoking_stats_service.dart';
import '../services/time_formatter.dart';
import '../widgets/allowed_time_window_sheet.dart';
import '../widgets/main_banner_ad_slot.dart';
import '../widgets/pen_design_widgets.dart';

part 'step1_screen_view_data.dart';
part 'step1_screen_home.dart';
part 'step1_screen_home_hero.dart';
part 'step1_screen_home_status.dart';
part 'step1_screen_home_summary.dart';
part 'step1_screen_record.dart';
part 'step1_screen_record_sections.dart';
part 'step1_screen_record_components.dart';
part 'step1_screen_alert.dart';
part 'step1_screen_alert_overview.dart';
part 'step1_screen_alert_sections.dart';
part 'step1_screen_settings.dart';
part 'step1_screen_settings_sections.dart';
part 'step1_screen_settings_components.dart';
part 'step1_screen_feedback_actions.dart';
part 'step1_screen_alert_actions.dart';
part 'step1_screen_settings_actions.dart';

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
    final appConfig = ref.watch(appConfigProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final viewData = _Step1ScreenViewData.fromState(state);
    final monetization = appConfig.monetization;

    return Scaffold(
      backgroundColor: ui.background,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _scrollableTab(
              key: const PageStorageKey('tab_home'),
              child: _HomeCard(
                hasRingBaseTime: viewData.hasRingBaseTime,
                elapsedMinutes: viewData.elapsedMinutes,
                intervalMinutes: state.settings.intervalMinutes,
                ringProgress: viewData.ringProgress,
                todayCount: viewData.todayCount,
                canUndo: viewData.canUndo,
                now: state.now,
                nextAlertAt: state.nextAlertAt,
                repeatEnabled: state.settings.repeatEnabled,
                hasSelectedWeekdays: state.settings.activeWeekdays.isNotEmpty,
                preAlertMinutes: state.settings.preAlertMinutes,
                use24Hour: state.settings.use24Hour,
                isCostConfigured: viewData.isCostConfigured,
                todaySpendText: viewData.todaySpendText,
                monthSpendText: viewData.monthSpendText,
                lifetimeSpendText: viewData.lifetimeSpendText,
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
                records: viewData.periodRecords,
                now: state.now,
                totalCount: viewData.totalCount,
                averageIntervalText: viewData.averageIntervalText,
                maxIntervalText: viewData.maxIntervalText,
                use24Hour: state.settings.use24Hour,
                isCostConfigured: viewData.isCostConfigured,
                periodSpendText: viewData.periodSpendText,
                averageDailySpendText: viewData.averageDailySpendText,
                onPeriodChanged: (period) => controller.setRecordPeriod(period),
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
                alertSummary: viewData.alertSummary,
                isCostConfigured: viewData.isCostConfigured,
                packPriceText: viewData.packPriceText,
                cigarettesPerPack: state.settings.cigarettesPerPack,
                currencyLabel: state.settings.currencyLabel,
                onToggle24Hour: () => _runSettingAction(
                  () => controller.toggleUse24Hour(),
                  state.settings.use24Hour
                      ? '12시간 표기로 바꿨어요.'
                      : '24시간 표기로 바꿨어요.',
                ),
                onToggleDarkMode: () => _runSettingAction(
                  () => controller.toggleDarkMode(),
                  state.settings.darkModeEnabled
                      ? '라이트 모드로 전환했어요.'
                      : '다크 모드로 전환했어요.',
                ),
                onCycleRingReference: () => _runSettingAction(
                  () => controller.cycleRingReference(),
                  '홈 원형 기준을 변경했어요.',
                ),
                onToggleVibration: () => _runSettingAction(
                  () => controller.toggleVibration(),
                  state.settings.vibrationEnabled ? '진동을 껐어요.' : '진동을 켰어요.',
                ),
                onCycleSoundType: () => _runSettingAction(
                  () => controller.cycleSoundType(),
                  '알림 소리를 변경했어요.',
                ),
                onOpenAlertSettings: () => _openAlertSettings(context),
                onEditPackPrice: () => _pickPackPrice(context, state),
                onEditCigarettesPerPack: () =>
                    _pickCigarettesPerPack(context, state),
                onEditCurrency: () => _pickCurrencyCode(context, state),
                onOpenPrivacyPolicy: () => _openPrivacyPolicy(context),
                onResetData: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (monetization.shouldShowBannerForTab(_tabIndex))
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

  /// Switches the main shell back to the Home tab.
  Future<void> _openHomeTab() async {
    if (!mounted) {
      return;
    }
    setState(() => _tabIndex = 0);
  }

  /// Switches the main shell to the settings tab so pricing can be edited.
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

  // TimeOfDay helper removed: time window is now selected via RangeSlider sheet.
}
