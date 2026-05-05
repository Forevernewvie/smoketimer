part of 'step1_screen.dart';

class _AlertOverviewCard extends StatelessWidget {
  const _AlertOverviewCard({required this.presentation});

  final AlertSettingsPresentation presentation;

  /// Renders the alert overview header with summary chips and next schedule.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final repeatTonePalette = _AlertTonePalette.fromTone(
      presentation.repeatChipTone,
    );
    final scheduleTonePalette = _AlertTonePalette.fromTone(
      presentation.scheduleChipTone,
    );

    return SurfaceCard(
      color: ui.surfaceAlt,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(14),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SmokeUiSpacing.xs,
            runSpacing: SmokeUiSpacing.xs,
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
          const SizedBox(height: SmokeUiSpacing.sm),
          const SectionLabel(text: '다음 일정'),
          const SizedBox(height: SmokeUiSpacing.xxs),
          Text(
            presentation.nextAlertPreviewText,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SmokeUiSpacing.sm),
          _AlertOverviewMetricsGrid(presentation: presentation),
        ],
      ),
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
          borderColor: SmokeUiPalette.infoBorder,
        );
      case AlertSettingsTone.warning:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.warning,
          backgroundColor: SmokeUiPalette.warningSoft,
          borderColor: SmokeUiPalette.warningBorder,
        );
      case AlertSettingsTone.success:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.mint,
          backgroundColor: SmokeUiPalette.mintSoft,
          borderColor: SmokeUiPalette.mintBorder,
        );
      case AlertSettingsTone.risk:
        return const _AlertTonePalette(
          foregroundColor: SmokeUiPalette.risk,
          backgroundColor: SmokeUiPalette.riskSoft,
          borderColor: SmokeUiPalette.riskBorder,
        );
    }
  }
}

class _AlertOverviewMetric extends StatelessWidget {
  const _AlertOverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  /// Renders one overview metric in the alert summary header.
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
          const SizedBox(height: SmokeUiSpacing.xxs),
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

class _AlertOverviewMetricsGrid extends StatelessWidget {
  const _AlertOverviewMetricsGrid({required this.presentation});

  final AlertSettingsPresentation presentation;

  /// Keeps summary metrics visually balanced on narrow alert-setting screens.
  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AlertOverviewMetric(label: '간격', value: presentation.intervalLabel),
      _AlertOverviewMetric(label: '시간대', value: presentation.rangeText),
      _AlertOverviewMetric(
        label: '활성 요일',
        value: presentation.weekdayCountText,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 300
            ? 3
            : maxWidth >= 210
            ? 2
            : 1;
        final spacing = SmokeUiSpacing.xs;
        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((metric) => SizedBox(width: itemWidth, child: metric))
              .toList(growable: false),
        );
      },
    );
  }
}
