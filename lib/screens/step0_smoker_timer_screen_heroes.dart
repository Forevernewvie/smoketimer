part of 'step0_smoker_timer_screen.dart';

class _RingHero extends StatelessWidget {
  const _RingHero();

  static const _heroSize = 160.0;
  static const _innerSize = 122.0;
  static const _ringSweepAngle = 4.95;

  /// Shows the timer-focused onboarding hero.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final centerFill = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1318)
        : const Color(0xFF121417);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      strokeColor: ui.border,
      color: ui.surface,
      cornerRadius: 18,
      child: SizedBox(
        height: _heroSize,
        child: Center(
          child: SizedBox(
            width: _heroSize,
            height: _heroSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RingGauge(
                  size: _heroSize,
                  strokeWidth: 10,
                  trackColor: ui.ringTrack,
                  sweepAngle: _ringSweepAngle,
                  value: ' ',
                  label: ' ',
                  valueStyle: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                ),
                Container(
                  width: _innerSize,
                  height: _innerSize,
                  decoration: BoxDecoration(
                    color: centerFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '42',
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontFamily: 'Sora',
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '분 경과',
                          style: TextStyle(
                            color: Color(0xFFD0D7E2),
                            fontSize: 11,
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
      ),
    );
  }
}

class _BarHero extends StatelessWidget {
  const _BarHero();

  /// Shows the history-pattern onboarding hero.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(16),
      cornerRadius: 18,
      child: SizedBox(
        height: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 패턴 요약',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _BarChartPillar(height: 62, color: Color(0xFFFFD8B8)),
                  _BarChartPillar(height: 94, color: Color(0xFFFFB67E)),
                  _BarChartPillar(height: 52, color: Color(0xFFFFE4CE)),
                  _BarChartPillar(height: 112, color: SmokeUiPalette.accent),
                  _BarChartPillar(height: 74, color: SmokeUiPalette.mint),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ui.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ui.border),
              ),
              child: Text(
                '최근 7일 대비 +18분',
                style: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero();

  /// Shows the alert-summary onboarding hero.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(16),
      cornerRadius: 18,
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: SmokeUiPalette.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: SmokeUiPalette.accentDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '다음 알림 00:28:10',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: ui.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ui.border),
              ),
              child: Text(
                '허용 시간대 06:00 ~ 23:30',
                style: TextStyle(
                  color: ui.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ui.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ui.border),
                    ),
                    child: Text(
                      '반복 요일: 월~금',
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ui.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ui.border),
                    ),
                    child: Text(
                      '미리 알림 5분 전',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPillar extends StatelessWidget {
  const _BarChartPillar({required this.height, required this.color});

  static const _pillarWidth = 30.0;

  final double height;
  final Color color;

  /// Draws a single decorative bar used in the onboarding pattern hero.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _pillarWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    );
  }
}
