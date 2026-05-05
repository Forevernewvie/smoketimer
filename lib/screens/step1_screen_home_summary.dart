part of 'step1_screen.dart';

class _HomeRhythmCoachCard extends StatelessWidget {
  const _HomeRhythmCoachCard({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.intervalMinutes,
    required this.todayCount,
  });

  final bool hasRingBaseTime;
  final int elapsedMinutes;
  final int intervalMinutes;
  final int todayCount;

  /// Gives a planning nudge using existing timer/count data only.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final remainingMinutes = max(0, intervalMinutes - elapsedMinutes);
    final isBeyondTarget = hasRingBaseTime && remainingMinutes == 0;
    final chipText = !hasRingBaseTime
        ? '준비 전'
        : isBeyondTarget
        ? '넘김'
        : '미루는 중';
    final title = !hasRingBaseTime
        ? '첫 기록 뒤부터 간격 리듬을 보여드려요.'
        : isBeyondTarget
        ? '목표 간격을 넘겼어요. 다음 한 번은 더 늦춰볼 수 있어요.'
        : '목표 간격까지 ${remainingMinutes.toString()}분, 지금은 숨 고르기 구간이에요.';
    final detail = todayCount == 0
        ? '기록을 강요하지 않고, 시작 후 타이머·알림·비용만 차분하게 연결합니다.'
        : '오늘 기록 ${todayCount.toString()}건을 기준으로 간격을 읽고 다음 선택을 가볍게 미룹니다.';

    return Semantics(
      container: true,
      label: '오늘의 리듬 제안',
      child: SurfaceCard(
        color: ui.surface,
        strokeColor: ui.border,
        padding: const EdgeInsets.all(SmokeUiSpacing.md),
        cornerRadius: SmokeUiRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveHeaderRow(
              leading: const SectionLabel(text: '리듬 코치'),
              trailing: StatusChip(
                text: chipText,
                icon: isBeyondTarget
                    ? Icons.check_circle_outline_rounded
                    : Icons.air_rounded,
                foregroundColor: isBeyondTarget
                    ? SmokeUiPalette.mint
                    : SmokeUiPalette.accentDark,
                backgroundColor: isBeyondTarget
                    ? SmokeUiPalette.mintSoft
                    : SmokeUiPalette.accentSoft,
                borderColor: isBeyondTarget
                    ? const Color(0xFF94E3CF)
                    : const Color(0xFF8CE3F1),
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.xs),
            Text(
              detail,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            _ResponsiveHomeCardRow<_RhythmStepData>(
              breakpoint: 360,
              items: [
                _RhythmStepData(
                  icon: Icons.timer_outlined,
                  label: '타이머',
                  value: '${elapsedMinutes.toString()}분',
                ),
                _RhythmStepData(
                  icon: Icons.flag_outlined,
                  label: '목표 간격',
                  value: '${intervalMinutes.toString()}분',
                ),
                _RhythmStepData(
                  icon: Icons.smoking_rooms_outlined,
                  label: '오늘',
                  value: '${todayCount.toString()}건',
                ),
              ],
              itemBuilder: (data) => _RhythmStep(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _RhythmStepData {
  const _RhythmStepData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep({required this.data});

  final _RhythmStepData data;

  /// Renders one compact metric in the rhythm coach card.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surfaceAlt,
      strokeColor: ui.border,
      cornerRadius: SmokeUiRadius.sm,
      padding: const EdgeInsets.all(SmokeUiSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: SmokeUiPalette.accentDark),
          const SizedBox(width: SmokeUiSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CravingPauseCard extends StatelessWidget {
  const _CravingPauseCard();

  static const _steps = [
    _PauseStepData(icon: Icons.air_rounded, text: '숨 4번'),
    _PauseStepData(icon: Icons.water_drop_outlined, text: '물 한 잔'),
    _PauseStepData(icon: Icons.directions_walk_rounded, text: '자리 이동'),
  ];

  /// Offers a short local routine without adding medical claims or accounts.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Semantics(
      container: true,
      label: '3분 대기 루틴',
      child: SurfaceCard(
        color: ui.surfaceAlt,
        strokeColor: ui.border,
        padding: const EdgeInsets.all(SmokeUiSpacing.md),
        cornerRadius: SmokeUiRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveHeaderRow(
              leading: const SectionLabel(text: '3분 대기 루틴'),
              trailing: StatusChip(
                text: '앱 안에서만',
                icon: Icons.lock_outline_rounded,
                foregroundColor: SmokeUiPalette.accentDark,
                backgroundColor: SmokeUiPalette.accentSoft,
                borderColor: const Color(0xFF8CE3F1),
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            Text(
              '바로 기록하기 전, 한 번만 더 늦춰보는 짧은 체크입니다.',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.xs),
            Text(
              '계정 가입 없이 지금 화면에서 끝나는 행동 제안만 남겼어요.',
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SmokeUiSpacing.sm),
            _ResponsiveHomeCardRow<_PauseStepData>(
              breakpoint: 340,
              items: _steps,
              itemBuilder: (data) => _PauseStep(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseStepData {
  const _PauseStepData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _PauseStep extends StatelessWidget {
  const _PauseStep({required this.data});

  final _PauseStepData data;

  /// Renders one local action in the short pause routine.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      cornerRadius: SmokeUiRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: SmokeUiSpacing.xs,
        vertical: SmokeUiSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 15, color: SmokeUiPalette.accentDark),
          const SizedBox(width: SmokeUiSpacing.xxs),
          Flexible(
            child: Text(
              data.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveHomeCardRow<T> extends StatelessWidget {
  const _ResponsiveHomeCardRow({
    required this.breakpoint,
    required this.items,
    required this.itemBuilder,
  });

  final double breakpoint;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  /// Stacks compact card items before they can squeeze enough to overflow.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < breakpoint;
        if (stacked) {
          return Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: SmokeUiSpacing.xs),
                itemBuilder(items[index]),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: SmokeUiSpacing.xs),
              Expanded(child: itemBuilder(items[index])),
            ],
          ],
        );
      },
    );
  }
}

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      key: const Key('home_cost_summary_card'),
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
          ] else
            LayoutBuilder(
              builder: (context, constraints) {
                final canUseTwoColumns = constraints.maxWidth >= 240;
                if (!canUseTwoColumns) {
                  return Column(
                    children: [
                      _SpendMetric(label: '오늘 지출', value: todaySpendText),
                      const SizedBox(height: SmokeUiSpacing.xs),
                      _SpendMetric(label: '이번 달 지출', value: monthSpendText),
                      const SizedBox(height: SmokeUiSpacing.xs),
                      _SpendMetric(label: '누적 지출', value: lifetimeSpendText),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SpendMetric(
                            label: '오늘 지출',
                            value: todaySpendText,
                          ),
                        ),
                        const SizedBox(width: SmokeUiSpacing.xs),
                        Expanded(
                          child: _SpendMetric(
                            label: '이번 달 지출',
                            value: monthSpendText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SmokeUiSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: _SpendMetric(
                        label: '누적 지출',
                        value: lifetimeSpendText,
                      ),
                    ),
                  ],
                );
              },
            ),
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
