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
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      appBar: const FrameRouteAppBar(
        title: 'KM1Jk · Step 0 Smoker Timer',
        currentRoute: Step0SmokerTimerScreen.routeName,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: PhoneShell(
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
                    hero: const _RingHero(),
                  ),
                  _OnboardingPage(
                    index: 1,
                    title: '흡연 기록을 숫자로 확인',
                    description: '하루 흡연 횟수와 시간대를 자동으로 정리합니다.',
                    buttonText: '다음',
                    onButtonTap: _next,
                    onSkipTap: _skip,
                    hero: const _BarHero(),
                  ),
                  _OnboardingPage(
                    index: 2,
                    title: '알림 간격을 내 루틴에 맞게',
                    description: '다음 흡연 알림 시간을 자유롭게 설정하세요.',
                    buttonText: '시작하기',
                    onButtonTap: _next,
                    onSkipTap: _skip,
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
    required this.hero,
  });

  final int index;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onButtonTap;
  final VoidCallback onSkipTap;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: Row(
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
                child: const Text(
                  '건너뛰기',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        hero,
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PageDots(activeIndex: index),
              SizedBox(
                width: 112,
                child: PrimaryButton(
                  text: buttonText,
                  height: 44,
                  color: const Color(0xFF1D4ED8),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: onButtonTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingHero extends StatelessWidget {
  const _RingHero();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 250,
        child: Stack(
          children: const [
            Positioned(
              left: 70,
              top: 44,
              child: RingGauge(
                size: 140,
                strokeWidth: 10,
                sweepAngle: 5.12,
                value: '37',
                label: '분 경과',
                valueStyle: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
                labelStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarHero extends StatelessWidget {
  const _BarHero();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘 평균 간격',
              style: TextStyle(
                color: Color(0xFF0F172A),
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
                  _BarChartPillar(height: 72, color: Color(0xFFDBEAFE)),
                  _BarChartPillar(height: 102, color: Color(0xFF93C5FD)),
                  _BarChartPillar(height: 58, color: Color(0xFFBFDBFE)),
                  _BarChartPillar(height: 124, color: Color(0xFF2563EB)),
                  _BarChartPillar(height: 84, color: Color(0xFF60A5FA)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '최근 7일 대비 +18분',
              style: TextStyle(
                color: Color(0xFF64748B),
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
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: const SizedBox(
        height: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 30,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '오늘 누적 3회 기록',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '최근 기록: 오전 09:40',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
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
