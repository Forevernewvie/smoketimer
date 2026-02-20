import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/state/app_providers.dart';
import '../widgets/pen_design_widgets.dart';

class Step0SmokerTimerScreen extends ConsumerStatefulWidget {
  const Step0SmokerTimerScreen({super.key});

  static const routeName = '/step0-smoker-timer';

  @override
  ConsumerState<Step0SmokerTimerScreen> createState() =>
      _Step0SmokerTimerScreenState();
}

class _Step0SmokerTimerScreenState
    extends ConsumerState<Step0SmokerTimerScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_pageIndex < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    await ref.read(appControllerProvider.notifier).completeOnboarding();
  }

  Future<void> _skip() async {
    await ref.read(appControllerProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Scaffold(
      backgroundColor: ui.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: [
                  _OnboardingPage(
                    index: 0,
                    title: '경과 시간을 한눈에',
                    description: '마지막 기록 시점부터 자동으로 카운트됩니다.',
                    features: const [
                      '빠른 기록(+1) / 되돌리기',
                      '다음 흡연까지 남은 시간 확인',
                      '오늘 페이스를 직관적으로 확인',
                    ],
                    buttonText: '다음',
                    onButtonTap: _next,
                    onSkipTap: _skip,
                    onStartTap: _skip,
                    hero: const _RingHero(),
                  ),
                  _OnboardingPage(
                    index: 1,
                    title: '기록을 흐름으로 파악',
                    description: '하루 흡연 횟수와 시간대를 자동으로 정리합니다.',
                    features: const [
                      '오늘/주간/월간 탭 전환',
                      '총 개비 · 평균 간격 · 최장 간격',
                      '최근 기록 최대 20건 확인',
                    ],
                    buttonText: '다음',
                    onButtonTap: _next,
                    onSkipTap: _skip,
                    onStartTap: _skip,
                    hero: const _BarHero(),
                  ),
                  _OnboardingPage(
                    index: 2,
                    title: '알림 간격을 내 루틴에 맞게',
                    description: '다음 흡연 알림 시간을 자유롭게 설정하세요.',
                    features: const [
                      '반복 간격(30분~4시간) 설정',
                      '요일/허용 시간대 커스터마이즈',
                      '테스트 알림으로 즉시 확인',
                    ],
                    buttonText: '시작하기',
                    onButtonTap: _next,
                    onSkipTap: _skip,
                    onStartTap: _skip,
                    hero: const _SummaryHero(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.index,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onButtonTap,
    required this.onSkipTap,
    required this.onStartTap,
    required this.hero,
  });

  final int index;
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback onButtonTap;
  final VoidCallback onSkipTap;
  final VoidCallback onStartTap;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 730 || textScale > 1.25;
        final baseTitleSize = constraints.maxWidth < 360 ? 34.0 : 36.0;
        final scaledTitleSize =
            baseTitleSize / textScale.clamp(1.0, 1.35).toDouble();
        final titleSize = scaledTitleSize.clamp(24.0, 36.0).toDouble();
        final accentColor = switch (index) {
          0 => const Color(0xFF1D4ED8),
          1 => SmokeUiPalette.accentDark,
          _ => SmokeUiPalette.mint,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}/3',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSkipTap,
                  child: Text(
                    '건너뛰기',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: compact
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hero,
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: titleSize,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SurfaceCard(
                        padding: const EdgeInsets.all(14),
                        cornerRadius: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(features.length, (
                                  featureIndex,
                                ) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          featureIndex == features.length - 1
                                          ? 0
                                          : 8,
                                    ),
                                    child: Text(
                                      '• ${features[featureIndex]}',
                                      style: TextStyle(
                                        color: ui.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withValues(alpha: 0.24),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                index == 2
                                    ? Icons.notifications_active_rounded
                                    : Icons.radio_button_checked_rounded,
                                size: 16,
                                color: accentColor,
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PageDots(activeIndex: index),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: buttonText,
              height: 44,
              color: SmokeUiPalette.accent,
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              onTap: onButtonTap,
            ),
            const SizedBox(height: 10),
            Material(
              color: compact ? ui.surface : ui.surfaceAlt,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onStartTap,
                child: Container(
                  height: 44,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: ui.border),
                  ),
                  child: Text(
                    '앱 시작',
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RingHero extends StatelessWidget {
  const _RingHero();

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
      child: SizedBox(
        height: 160,
        child: Center(
          child: SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RingGauge(
                  size: 116,
                  strokeWidth: 8,
                  trackColor: ui.ringTrack,
                  sweepAngle: 4.95,
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
                  width: 74,
                  height: 74,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '분 경과',
                          style: TextStyle(
                            color: Color(0xFFD0D7E2),
                            fontSize: 10,
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

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SurfaceCard(
      color: ui.surface,
      strokeColor: ui.border,
      padding: const EdgeInsets.all(16),
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

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
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
