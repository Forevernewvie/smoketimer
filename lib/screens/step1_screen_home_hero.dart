part of 'step1_screen.dart';

class _HomeHeroSection extends StatelessWidget {
  const _HomeHeroSection({
    required this.hasRingBaseTime,
    required this.elapsedMinutes,
    required this.ringProgress,
    required this.ringSize,
    required this.compact,
    required this.tightHeight,
    required this.stackStatusPanels,
    required this.canUndo,
    required this.ringCenterFill,
    required this.intervalPresentation,
    required this.alertPresentation,
    required this.onAddRecord,
    required this.onUndoRecord,
    required this.onOpenAlertSettings,
  });

  static const _alertButtonMaxWidth = 128.0;
  static const _ringStrokeWidth = 12.0;
  static const _ringCenterScale = 0.66;
  static const _heroShadowAlpha = 0.03;
  static const _heroShadowBlur = 20.0;
  static const _heroShadowOffsetY = 10.0;
  static const _heroCompactPadding = 14.0;
  static const _heroCompactDetailFontSize = 12.0;
  static const _heroDetailFontSize = 13.0;
  static const _ringValueFontSize = 52.0;
  static const _ringLabelFontSize = 12.0;
  static const _transparentFontSize = 1.0;
  static const _ringLabelSpacing = 2.0;

  final bool hasRingBaseTime;
  final int elapsedMinutes;
  final double ringProgress;
  final double ringSize;
  final bool compact;
  final bool tightHeight;
  final bool stackStatusPanels;
  final bool canUndo;
  final Color ringCenterFill;
  final HomeStatusPresentation intervalPresentation;
  final HomeStatusPresentation alertPresentation;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;
  final Future<void> Function() onOpenAlertSettings;

  /// Builds the primary home hero with the timer ring, status panels, and CTA.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _heroShadowAlpha),
          blurRadius: _heroShadowBlur,
          offset: const Offset(0, _heroShadowOffsetY),
        ),
      ],
      padding: EdgeInsets.all(
        tightHeight ? _heroCompactPadding : SmokeUiSpacing.md,
      ),
      cornerRadius: SmokeUiRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeroHeader(
            tightHeight: tightHeight,
            onOpenAlertSettings: onOpenAlertSettings,
          ),
          SizedBox(height: tightHeight ? SmokeUiSpacing.sm : SmokeUiSpacing.md),
          Center(
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RingGauge(
                    size: ringSize,
                    strokeWidth: _ringStrokeWidth,
                    trackColor: ui.ringTrack,
                    sweepAngle: ringProgress * 2 * pi,
                    value: ' ',
                    label: ' ',
                    valueStyle: const TextStyle(
                      color: Colors.transparent,
                      fontSize: _transparentFontSize,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.transparent,
                      fontSize: _transparentFontSize,
                    ),
                  ),
                  Container(
                    width: ringSize * _ringCenterScale,
                    height: ringSize * _ringCenterScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ringCenterFill,
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            elapsedMinutes.toString(),
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontFamily: 'Sora',
                              fontSize: _ringValueFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: _ringLabelSpacing),
                          const Text(
                            '분 경과',
                            style: TextStyle(
                              color: Color(0xFFD0D7E2),
                              fontSize: _ringLabelFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: tightHeight ? SmokeUiSpacing.xs : SmokeUiSpacing.sm),
          Center(
            child: Text(
              hasRingBaseTime
                  ? '마지막 기록 후 ${elapsedMinutes.toString()}분 지났어요.'
                  : '첫 기록을 남기면 타이머가 시작돼요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: tightHeight
                    ? _heroCompactDetailFontSize
                    : _heroDetailFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: tightHeight ? SmokeUiSpacing.sm : SmokeUiSpacing.md),
          _HomeHeroStatusArea(
            compact: compact,
            tightHeight: tightHeight,
            stackStatusPanels: stackStatusPanels,
            canUndo: canUndo,
            intervalPresentation: intervalPresentation,
            alertPresentation: alertPresentation,
            onAddRecord: onAddRecord,
            onUndoRecord: onUndoRecord,
          ),
        ],
      ),
    );
  }
}

class _HomeHeroHeader extends StatelessWidget {
  const _HomeHeroHeader({
    required this.tightHeight,
    required this.onOpenAlertSettings,
  });

  static const _heroTitleCompactFontSize = 28.0;
  static const _heroTitleFontSize = 30.0;
  static const _headerButtonHeight = 40.0;

  final bool tightHeight;
  final Future<void> Function() onOpenAlertSettings;

  /// Renders the hero title block and the shortcut to alert settings.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '흡연 타이머',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontFamily: 'Sora',
                  fontSize: tightHeight
                      ? _heroTitleCompactFontSize
                      : _heroTitleFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: SmokeUiSpacing.xxs),
              Text(
                '지금 상태를 빠르게 확인하고 바로 기록하세요.',
                style: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: SmokeUiSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _HomeHeroSection._alertButtonMaxWidth,
          ),
          child: SecondaryButton(
            text: '알림 설정',
            icon: Icons.notifications_none_rounded,
            height: _headerButtonHeight,
            foregroundColor: ui.textPrimary,
            backgroundColor: ui.surfaceAlt,
            borderColor: ui.border,
            onTap: () async {
              await onOpenAlertSettings();
            },
          ),
        ),
      ],
    );
  }
}

class _HomeHeroStatusArea extends StatelessWidget {
  const _HomeHeroStatusArea({
    required this.compact,
    required this.tightHeight,
    required this.stackStatusPanels,
    required this.canUndo,
    required this.intervalPresentation,
    required this.alertPresentation,
    required this.onAddRecord,
    required this.onUndoRecord,
  });

  final bool compact;
  final bool tightHeight;
  final bool stackStatusPanels;
  final bool canUndo;
  final HomeStatusPresentation intervalPresentation;
  final HomeStatusPresentation alertPresentation;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;

  /// Renders responsive status panels and CTA placement for the home hero.
  @override
  Widget build(BuildContext context) {
    final actions = _HomePrimaryActions(
      compact: compact,
      canUndo: canUndo,
      onAddRecord: onAddRecord,
      onUndoRecord: onUndoRecord,
    );

    if (compact) {
      return Column(
        children: [
          actions,
          SizedBox(height: tightHeight ? SmokeUiSpacing.sm : SmokeUiSpacing.md),
          _HomeStatusPanel(label: '지금 상태', presentation: intervalPresentation),
          const SizedBox(height: SmokeUiSpacing.sm),
          _HomeStatusPanel(label: '다음 알림', presentation: alertPresentation),
        ],
      );
    }

    if (stackStatusPanels) {
      return Column(
        children: [
          _HomeStatusPanel(label: '지금 상태', presentation: intervalPresentation),
          const SizedBox(height: SmokeUiSpacing.sm),
          _HomeStatusPanel(label: '다음 알림', presentation: alertPresentation),
          SizedBox(height: tightHeight ? SmokeUiSpacing.sm : SmokeUiSpacing.md),
          actions,
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HomeStatusPanel(
                label: '지금 상태',
                presentation: intervalPresentation,
              ),
            ),
            const SizedBox(width: SmokeUiSpacing.sm),
            Expanded(
              child: _HomeStatusPanel(
                label: '다음 알림',
                presentation: alertPresentation,
              ),
            ),
          ],
        ),
        SizedBox(height: tightHeight ? SmokeUiSpacing.sm : SmokeUiSpacing.md),
        actions,
      ],
    );
  }
}

class _HomePrimaryActions extends StatelessWidget {
  const _HomePrimaryActions({
    required this.compact,
    required this.canUndo,
    required this.onAddRecord,
    required this.onUndoRecord,
  });

  static const _actionFontSize = 15.0;

  final bool compact;
  final bool canUndo;
  final Future<void> Function() onAddRecord;
  final Future<void> Function() onUndoRecord;

  /// Renders the primary record CTA and the lower-priority undo action.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final undoButton = SecondaryButton(
      text: '되돌리기',
      icon: Icons.undo_rounded,
      foregroundColor: ui.textSecondary,
      backgroundColor: ui.surfaceAlt,
      borderColor: ui.border,
      onTap: canUndo
          ? () async {
              await onUndoRecord();
            }
          : null,
    );
    final addButton = PrimaryButton(
      text: '지금 흡연 기록',
      icon: Icons.add_rounded,
      color: SmokeUiPalette.accent,
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: _actionFontSize,
        fontWeight: FontWeight.w700,
      ),
      onTap: () async {
        await onAddRecord();
      },
    );

    if (compact) {
      return Column(
        children: [
          addButton,
          const SizedBox(height: SmokeUiSpacing.sm),
          undoButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: addButton),
        const SizedBox(width: SmokeUiSpacing.sm),
        Expanded(flex: 2, child: undoButton),
      ],
    );
  }
}
