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
                    buttonText: '다음',
                    onButtonTap: _next,
                    onSkipTap: _skip,
                    onStartTap: _skip,
                    hero: const _RingHero(),
                  ),
                  _OnboardingPage(
                    index: 1,
                    title: '흡연 기록을 숫자로 확인',
                    description: '하루 흡연 횟수와 시간대를 자동으로 정리합니다.',
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
    required this.buttonText,
    required this.onButtonTap,
    required this.onSkipTap,
    required this.onStartTap,
    required this.hero,
  });

  final int index;
  final String title;
  final String description;
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
                        fontSize: 40 / textScale.clamp(1.0, 1.4).toDouble(),
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
                    SurfaceCard(
                      padding: const EdgeInsets.all(14),
                      cornerRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• 빠른 기록(+1) / 되돌리기',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 기간별 기록 통계',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 로컬 알림 스케줄',
                            style: TextStyle(
                              color: ui.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      strokeColor: ui.border,
      color: ui.surface,
      child: SizedBox(
        height: 160,
        child: Center(
          child: RingGauge(
            size: 160,
            strokeWidth: 10,
            trackColor: ui.ringTrack,
            sweepAngle: 4.6,
            value: '42',
            label: '분 경과',
            valueStyle: TextStyle(
              color: ui.textPrimary,
              fontFamily: 'Sora',
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
            labelStyle: TextStyle(
              color: ui.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
              '오늘 평균 간격',
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _BarChartPillar(height: 72, color: Color(0xFFFFD8B8)),
                  _BarChartPillar(height: 102, color: Color(0xFFFFB67E)),
                  _BarChartPillar(height: 58, color: Color(0xFFFFE4CE)),
                  _BarChartPillar(height: 124, color: SmokeUiPalette.accent),
                  _BarChartPillar(height: 84, color: SmokeUiPalette.mint),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '최근 7일 대비 +18분',
              style: TextStyle(
                color: Color(0xFF5A6472),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SmokeUiPalette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 30,
                  color: SmokeUiPalette.accentDark,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '오늘 누적 3회 기록',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '최근 기록: 오전 09:40',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
      width: 36,
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
