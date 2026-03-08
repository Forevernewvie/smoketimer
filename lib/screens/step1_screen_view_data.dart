part of 'step1_screen.dart';

/// Bundles all derived values needed to render the main tabs.
class _Step1ScreenViewData {
  const _Step1ScreenViewData({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.ringProgress,
    required this.todayCount,
    required this.canUndo,
    required this.periodRecords,
    required this.totalCount,
    required this.averageIntervalText,
    required this.maxIntervalText,
    required this.isCostConfigured,
    required this.todaySpendText,
    required this.monthSpendText,
    required this.lifetimeSpendText,
    required this.periodSpendText,
    required this.averageDailySpendText,
    required this.alertSummary,
    required this.packPriceText,
  });

  final bool hasRingBaseTime;
  final int elapsedMinutes;
  final double ringProgress;
  final int todayCount;
  final bool canUndo;
  final List<SmokingRecord> periodRecords;
  final int totalCount;
  final String averageIntervalText;
  final String maxIntervalText;
  final bool isCostConfigured;
  final String todaySpendText;
  final String monthSpendText;
  final String lifetimeSpendText;
  final String periodSpendText;
  final String averageDailySpendText;
  final String alertSummary;
  final String packPriceText;

  /// Computes all presentation-only values from the current application state.
  factory _Step1ScreenViewData.fromState(AppState state) {
    final sortedRecords = [...state.records]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
    final todayRecords = _recordsForPeriod(
      sortedRecords: sortedRecords,
      period: RecordPeriod.today,
      now: state.now,
    );
    final monthRecords = _recordsForPeriod(
      sortedRecords: sortedRecords,
      period: RecordPeriod.month,
      now: state.now,
    );
    final periodRecords = _recordsForPeriod(
      sortedRecords: sortedRecords,
      period: state.recordPeriod,
      now: state.now,
    );
    final totalCount = SmokingStatsService.totalCount(periodRecords);
    final averageInterval = SmokingStatsService.averageIntervalMinutes(
      periodRecords,
    );
    final maxInterval = SmokingStatsService.maxIntervalMinutes(periodRecords);
    final hasIntervalStats = periodRecords.length >= 2;
    final isCostConfigured = CostStatsService.isConfigured(state.settings);
    final todayCount = SmokingStatsService.totalCount(todayRecords);
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

    return _Step1ScreenViewData(
      hasRingBaseTime: ringBaseTime != null,
      elapsedMinutes: elapsedMinutes,
      ringProgress: ringProgress,
      todayCount: todayCount,
      canUndo: state.records.isNotEmpty,
      periodRecords: periodRecords,
      totalCount: totalCount,
      averageIntervalText: _formatIntervalText(
        value: averageInterval,
        hasStats: hasIntervalStats,
      ),
      maxIntervalText: _formatIntervalText(
        value: maxInterval,
        hasStats: hasIntervalStats,
      ),
      isCostConfigured: isCostConfigured,
      todaySpendText: CostStatsService.formatCurrency(
        todaySpend,
        state.settings,
      ),
      monthSpendText: CostStatsService.formatCurrency(
        monthSpend,
        state.settings,
      ),
      lifetimeSpendText: CostStatsService.formatCurrency(
        lifetimeSpend,
        state.settings,
      ),
      periodSpendText: CostStatsService.formatCurrency(
        periodSpend,
        state.settings,
      ),
      averageDailySpendText: CostStatsService.formatCurrency(
        averageDailySpend,
        state.settings,
      ),
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
      packPriceText: state.settings.packPrice > 0
          ? CostStatsService.formatCurrency(
              state.settings.packPrice,
              state.settings,
            )
          : '미설정',
    );
  }

  /// Filters sorted smoking records into the requested record period.
  static List<SmokingRecord> _recordsForPeriod({
    required List<SmokingRecord> sortedRecords,
    required RecordPeriod period,
    required DateTime now,
  }) {
    final start = SmokingStatsService.startOfPeriod(period, now);
    return sortedRecords
        .where((record) => !record.timestamp.isBefore(start))
        .toList(growable: false);
  }

  /// Formats interval statistics while preserving the empty-state placeholder.
  static String _formatIntervalText({
    required int value,
    required bool hasStats,
  }) {
    if (!hasStats) {
      return '-';
    }
    return '${value.toString()}분';
  }
}
