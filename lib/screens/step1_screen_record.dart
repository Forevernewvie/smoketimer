part of 'step1_screen.dart';

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

  static const _stackedSummaryBreakpoint = 380.0;
  static const _stackedSummaryTextScaleBreakpoint = 1.15;

  /// Builds the record overview, summary metrics, and record history list.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackedSummaryCards =
            constraints.maxWidth < _stackedSummaryBreakpoint ||
            textScale > _stackedSummaryTextScaleBreakpoint;
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
            _RecordPeriodSelector(
              period: period,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: SmokeUiSpacing.md),
            _RecordSummarySection(
              stackedCards: stackedSummaryCards,
              totalCount: totalCount,
              averageIntervalText: averageIntervalText,
              maxIntervalText: maxIntervalText,
            ),
            const SizedBox(height: SmokeUiSpacing.md),
            _RecordCostInsightsSection(
              stackedCards: stackedSummaryCards,
              isCostConfigured: isCostConfigured,
              totalCount: totalCount,
              periodSpendText: periodSpendText,
              averageDailySpendText: averageDailySpendText,
              onOpenPricingSettings: onOpenPricingSettings,
            ),
            const SizedBox(height: SmokeUiSpacing.md),
            _RecordHistorySection(
              now: now,
              records: records,
              use24Hour: use24Hour,
              onOpenHomeTab: onOpenHomeTab,
            ),
          ],
        );
      },
    );
  }
}
