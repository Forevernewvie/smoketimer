part of 'step1_screen.dart';

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.intervalMinutes,
    required this.ringProgress,
    required this.todayCount,
    required this.canUndo,
    required this.now,
    required this.nextAlertAt,
    required this.repeatEnabled,
    required this.hasSelectedWeekdays,
    required this.preAlertMinutes,
    required this.use24Hour,
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
  final bool canUndo;
  final DateTime now;
  final DateTime? nextAlertAt;
  final bool repeatEnabled;
  final bool hasSelectedWeekdays;
  final int preAlertMinutes;
  final bool use24Hour;
  final bool isCostConfigured;
  final String todaySpendText;
  final String monthSpendText;
  final String lifetimeSpendText;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;
  final Future<void> Function() onOpenAlertSettings;
  final Future<void> Function() onOpenPricingSettings;

  static const _compactWidthBreakpoint = 390.0;
  static const _stackedInsightsBreakpoint = 460.0;
  static const _stackStatusBreakpoint = 340.0;
  static const _tightHeightBreakpoint = 760.0;
  static const _compactTextScaleBreakpoint = 1.15;
  static const _stackedInsightsTextScaleBreakpoint = 1.2;
  static const _stackStatusTextScaleBreakpoint = 1.25;
  static const _compactRingHorizontalInset = 72.0;
  static const _compactTightRingHorizontalInset = 88.0;
  static const _compactRingMin = 176.0;
  static const _compactTightRingMin = 164.0;
  static const _compactRingMax = 196.0;
  static const _compactTightRingMax = 184.0;
  static const _regularRingHorizontalInset = 48.0;
  static const _regularRingMin = 188.0;
  static const _regularTightRingMin = 184.0;
  static const _regularRingMax = 228.0;
  static const _regularTightRingMax = 208.0;

  /// Builds the home dashboard with the timer hero and supporting summaries.
  @override
  Widget build(BuildContext context) {
    final ringCenterFill = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1318)
        : const Color(0xFF121417);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final intervalPresentation = HomeStatusPresenter.buildIntervalStatus(
      HomeIntervalStatusInput(
        hasRingBaseTime: hasRingBaseTime,
        elapsedMinutes: elapsedMinutes,
        intervalMinutes: intervalMinutes,
      ),
    );
    final alertPresentation = HomeStatusPresenter.buildAlertStatus(
      HomeAlertStatusInput(
        hasRingBaseTime: hasRingBaseTime,
        repeatEnabled: repeatEnabled,
        hasSelectedWeekdays: hasSelectedWeekdays,
        preAlertMinutes: preAlertMinutes,
        now: now,
        nextAlertAt: nextAlertAt,
        use24Hour: use24Hour,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < _compactWidthBreakpoint ||
            textScale > _compactTextScaleBreakpoint;
        final tightHeight =
            MediaQuery.sizeOf(context).height < _tightHeightBreakpoint;
        final stackedInsights =
            constraints.maxWidth < _stackedInsightsBreakpoint ||
            textScale > _stackedInsightsTextScaleBreakpoint;
        final stackStatusPanels =
            (constraints.maxWidth < _stackStatusBreakpoint && !tightHeight) ||
            textScale > _stackStatusTextScaleBreakpoint;
        final ringSize = _resolveRingSize(
          constraints,
          compact: compact,
          tightHeight: tightHeight,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeroSection(
              hasRingBaseTime: hasRingBaseTime,
              elapsedMinutes: elapsedMinutes,
              ringProgress: ringProgress,
              ringSize: ringSize,
              compact: compact,
              tightHeight: tightHeight,
              stackStatusPanels: stackStatusPanels,
              canUndo: canUndo,
              ringCenterFill: ringCenterFill,
              intervalPresentation: intervalPresentation,
              alertPresentation: alertPresentation,
              onAddRecord: onAddRecord,
              onUndoRecord: onUndoRecord,
              onOpenAlertSettings: onOpenAlertSettings,
            ),
            const SizedBox(height: SmokeUiSpacing.lg),
            const SectionLabel(text: '오늘 요약'),
            const SizedBox(height: SmokeUiSpacing.xs),
            _HomeSummarySection(
              stacked: stackedInsights,
              todayCount: todayCount,
              isCostConfigured: isCostConfigured,
              todaySpendText: todaySpendText,
              monthSpendText: monthSpendText,
              lifetimeSpendText: lifetimeSpendText,
              onOpenPricingSettings: onOpenPricingSettings,
            ),
          ],
        );
      },
    );
  }

  /// Calculates a ring size that preserves the hero layout on short screens.
  double _resolveRingSize(
    BoxConstraints constraints, {
    required bool compact,
    required bool tightHeight,
  }) {
    if (compact) {
      return min(
            constraints.maxWidth -
                (tightHeight
                    ? _compactTightRingHorizontalInset
                    : _compactRingHorizontalInset),
            tightHeight ? _compactTightRingMax : _compactRingMax,
          )
          .clamp(
            tightHeight ? _compactTightRingMin : _compactRingMin,
            tightHeight ? _compactTightRingMax : _compactRingMax,
          )
          .toDouble();
    }

    return min(
          constraints.maxWidth - _regularRingHorizontalInset,
          tightHeight ? _regularTightRingMax : _regularRingMax,
        )
        .clamp(
          tightHeight ? _regularTightRingMin : _regularRingMin,
          tightHeight ? _regularTightRingMax : _regularRingMax,
        )
        .toDouble();
  }
}
