part of 'step1_screen.dart';

class _AlertOverviewCard extends StatelessWidget {
  const _AlertOverviewCard({required this.presentation, required this.compact});

  final AlertSettingsPresentation presentation;
  final bool compact;

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
          if (compact) ...[
            _AlertOverviewMetric(
              label: '간격',
              value: presentation.intervalLabel,
            ),
            const SizedBox(height: SmokeUiSpacing.xs),
            _AlertOverviewMetric(label: '시간대', value: presentation.rangeText),
            const SizedBox(height: SmokeUiSpacing.xs),
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
                const SizedBox(width: SmokeUiSpacing.xs),
                Expanded(
                  child: _AlertOverviewMetric(
                    label: '시간대',
                    value: presentation.rangeText,
                  ),
                ),
                const SizedBox(width: SmokeUiSpacing.xs),
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
