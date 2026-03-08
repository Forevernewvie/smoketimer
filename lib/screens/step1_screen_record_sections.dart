part of 'step1_screen.dart';

class _RecordPeriodSelector extends StatelessWidget {
  const _RecordPeriodSelector({
    required this.period,
    required this.onPeriodChanged,
  });

  static const _selectorHeight = 46.0;

  final RecordPeriod period;
  final ValueChanged<RecordPeriod> onPeriodChanged;

  /// Renders the period selection control for the record dashboard.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(SmokeUiSpacing.xs),
      cornerRadius: SmokeUiRadius.md,
      child: SizedBox(
        height: _selectorHeight,
        child: Row(
          children: [
            Expanded(
              child: _PeriodTab(
                text: '오늘',
                selected: period == RecordPeriod.today,
                onTap: () => onPeriodChanged(RecordPeriod.today),
              ),
            ),
            const SizedBox(width: SmokeUiSpacing.xs),
            Expanded(
              child: _PeriodTab(
                text: '주간',
                selected: period == RecordPeriod.week,
                onTap: () => onPeriodChanged(RecordPeriod.week),
              ),
            ),
            const SizedBox(width: SmokeUiSpacing.xs),
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
    );
  }
}

class _RecordSummarySection extends StatelessWidget {
  const _RecordSummarySection({
    required this.stackedCards,
    required this.totalCount,
    required this.averageIntervalText,
    required this.maxIntervalText,
  });

  final bool stackedCards;
  final int totalCount;
  final String averageIntervalText;
  final String maxIntervalText;

  /// Displays the core period metrics with a responsive summary layout.
  @override
  Widget build(BuildContext context) {
    final secondaryCards = <Widget>[
      Expanded(
        child: _SummaryItem(
          label: '평균 간격',
          value: averageIntervalText,
          detail: '기록 사이 평균 간격',
          valueFontSize: 20,
        ),
      ),
      const SizedBox(width: SmokeUiSpacing.xs),
      Expanded(
        child: _SummaryItem(
          label: '최장 간격',
          value: maxIntervalText,
          detail: '가장 길었던 간격',
          valueFontSize: 20,
        ),
      ),
    ];

    return Column(
      children: [
        _SummaryItem(
          label: '총 개비',
          value: '$totalCount개비',
          detail: '선택한 기간 동안 남긴 총 기록 수예요.',
          valueFontSize: 28,
          emphasized: true,
        ),
        const SizedBox(height: SmokeUiSpacing.xs),
        if (stackedCards) ...[
          SizedBox(
            width: double.infinity,
            child: _SummaryItem(
              label: '평균 간격',
              value: averageIntervalText,
              detail: '기록 사이 평균 간격',
              valueFontSize: 20,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: _SummaryItem(
              label: '최장 간격',
              value: maxIntervalText,
              detail: '가장 길었던 간격',
              valueFontSize: 20,
            ),
          ),
        ] else
          Row(children: secondaryCards),
      ],
    );
  }
}

class _RecordCostInsightsSection extends StatelessWidget {
  const _RecordCostInsightsSection({
    required this.stackedCards,
    required this.isCostConfigured,
    required this.totalCount,
    required this.periodSpendText,
    required this.averageDailySpendText,
    required this.onOpenPricingSettings,
  });

  final bool stackedCards;
  final bool isCostConfigured;
  final int totalCount;
  final String periodSpendText;
  final String averageDailySpendText;
  final Future<void> Function() onOpenPricingSettings;

  /// Builds cost insight content or the pricing setup empty state.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(SmokeUiSpacing.sm),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: '비용 인사이트'),
          const SizedBox(height: 10),
          if (!isCostConfigured)
            _RecordCostEmptyState(onOpenPricingSettings: onOpenPricingSettings)
          else
            _RecordCostMetrics(
              stackedCards: stackedCards,
              totalCount: totalCount,
              periodSpendText: periodSpendText,
              averageDailySpendText: averageDailySpendText,
            ),
        ],
      ),
    );
  }
}

class _RecordCostEmptyState extends StatelessWidget {
  const _RecordCostEmptyState({required this.onOpenPricingSettings});

  final Future<void> Function() onOpenPricingSettings;

  /// Guides the user to configure pricing before showing spend statistics.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

class _RecordCostMetrics extends StatelessWidget {
  const _RecordCostMetrics({
    required this.stackedCards,
    required this.totalCount,
    required this.periodSpendText,
    required this.averageDailySpendText,
  });

  final bool stackedCards;
  final int totalCount;
  final String periodSpendText;
  final String averageDailySpendText;

  /// Renders configured cost metrics for the selected record period.
  @override
  Widget build(BuildContext context) {
    if (stackedCards) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _SummaryItem(
              label: '흡연 개비',
              value: '$totalCount개비',
              detail: '선택한 기간 합계',
              valueFontSize: 18,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: _SummaryItem(
              label: '예상 지출',
              value: periodSpendText,
              detail: '선택한 기간 기준',
              valueFontSize: 16,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: _SummaryItem(
              label: '일 평균',
              value: averageDailySpendText,
              detail: '하루 평균 예상 지출',
              valueFontSize: 16,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryItem(
            label: '흡연 개비',
            value: '$totalCount개비',
            detail: '선택한 기간 합계',
            valueFontSize: 18,
          ),
        ),
        const SizedBox(width: SmokeUiSpacing.xs),
        Expanded(
          child: _SummaryItem(
            label: '예상 지출',
            value: periodSpendText,
            detail: '선택한 기간 기준',
            valueFontSize: 16,
          ),
        ),
        const SizedBox(width: SmokeUiSpacing.xs),
        Expanded(
          child: _SummaryItem(
            label: '일 평균',
            value: averageDailySpendText,
            detail: '하루 평균 예상 지출',
            valueFontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _RecordHistorySection extends StatelessWidget {
  const _RecordHistorySection({
    required this.now,
    required this.records,
    required this.use24Hour,
    required this.onOpenHomeTab,
  });

  final DateTime now;
  final List<SmokingRecord> records;
  final bool use24Hour;
  final Future<void> Function() onOpenHomeTab;

  /// Wraps the record list in a shared card surface for the history section.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      cornerRadius: SmokeUiRadius.md,
      color: ui.surface,
      strokeColor: ui.border,
      child: _RecordList(
        now: now,
        records: records,
        use24Hour: use24Hour,
        onOpenHomeTab: onOpenHomeTab,
      ),
    );
  }
}
