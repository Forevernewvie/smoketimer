part of 'step1_screen.dart';

class _HomeSummarySection extends StatelessWidget {
  const _HomeSummarySection({
    required this.stacked,
    required this.todayCount,
    required this.isCostConfigured,
    required this.todaySpendText,
    required this.monthSpendText,
    required this.lifetimeSpendText,
    required this.onOpenPricingSettings,
  });

  final bool stacked;
  final int todayCount;
  final bool isCostConfigured;
  final String todaySpendText;
  final String monthSpendText;
  final String lifetimeSpendText;
  final Future<void> Function() onOpenPricingSettings;

  /// Arranges today's activity and cost insights for the home dashboard.
  @override
  Widget build(BuildContext context) {
    final costCard = _HomeCostSummaryCard(
      isCostConfigured: isCostConfigured,
      todaySpendText: todaySpendText,
      monthSpendText: monthSpendText,
      lifetimeSpendText: lifetimeSpendText,
      onOpenPricingSettings: onOpenPricingSettings,
    );

    if (stacked) {
      return Column(
        children: [
          _HomeTodaySummaryCard(todayCount: todayCount),
          const SizedBox(height: SmokeUiSpacing.sm),
          costCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _HomeTodaySummaryCard(todayCount: todayCount)),
        const SizedBox(width: SmokeUiSpacing.sm),
        Expanded(child: costCard),
      ],
    );
  }
}

class _HomeTodaySummaryCard extends StatelessWidget {
  const _HomeTodaySummaryCard({required this.todayCount});

  static const _summaryValueFontSize = 32.0;
  static const _summaryIconSize = 18.0;

  final int todayCount;

  /// Shows the current day's smoking count at a glance.
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
                size: _summaryIconSize,
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
              fontSize: _summaryValueFontSize,
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

  /// Shows cost insights or routes the user to pricing setup.
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

  /// Renders a single compact spend metric within the home summary card.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      cornerRadius: SmokeUiRadius.sm,
      strokeColor: ui.border,
      color: ui.surfaceAlt,
      padding: const EdgeInsets.fromLTRB(
        SmokeUiSpacing.xs,
        SmokeUiSpacing.xs,
        SmokeUiSpacing.xs,
        SmokeUiSpacing.sm,
      ),
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
          const SizedBox(height: SmokeUiSpacing.xxs),
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
