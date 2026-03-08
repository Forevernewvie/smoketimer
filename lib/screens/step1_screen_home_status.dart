part of 'step1_screen.dart';

class _HomeStatusPanel extends StatelessWidget {
  const _HomeStatusPanel({required this.label, required this.presentation});

  static const _headerMinHeight = 28.0;
  static const _panelPadding = 10.0;
  static const _titleSpacing = 6.0;
  static const _detailSpacing = 2.0;

  final String label;
  final HomeStatusPresentation presentation;

  /// Renders a stable home status panel with a left label and right chip.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final tonePalette = _StatusTonePalette.fromTone(presentation.tone);
    return SurfaceCard(
      color: ui.surfaceAlt,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(_panelPadding),
      cornerRadius: SmokeUiRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: _headerMinHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: ui.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
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
          ),
          const SizedBox(height: _titleSpacing),
          Text(
            presentation.title,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _detailSpacing),
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
