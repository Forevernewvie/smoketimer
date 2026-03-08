import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/state/app_providers.dart';
import '../widgets/pen_design_widgets.dart';

part 'step0_smoker_timer_screen_page.dart';
part 'step0_smoker_timer_screen_heroes.dart';

class Step0SmokerTimerScreen extends ConsumerStatefulWidget {
  const Step0SmokerTimerScreen({super.key});

  static const routeName = '/step0-smoker-timer';
  static const _pages = <_OnboardingPageContent>[
    _OnboardingPageContent(
      index: 0,
      title: '지금 얼마나 지났는지 바로 확인',
      description: '마지막 기록 후 경과 시간을 홈에서 바로 보여줘요.',
      features: <String>['기록과 되돌리기 한 번에', '다음 알림 상태 확인', '오늘 흐름 빠르게 파악'],
      buttonText: '다음',
      hero: _RingHero(),
    ),
    _OnboardingPageContent(
      index: 1,
      title: '기록은 빠르게, 흐름은 자동으로',
      description: '오늘, 주간, 월간 기록을 보기 쉽게 정리해요.',
      features: <String>['총 개비와 간격 통계', '최근 기록 최대 20건', '패턴 변화를 한눈에 확인'],
      buttonText: '다음',
      hero: _BarHero(),
    ),
    _OnboardingPageContent(
      index: 2,
      title: '알림은 생활 리듬에 맞게',
      description: '간격, 요일, 허용 시간대를 내 일정에 맞춰 조정해요.',
      features: <String>['30분~4시간 간격 설정', '요일과 시간대 세부 조정', '테스트 알림으로 바로 확인'],
      buttonText: '시작하기',
      hero: _SummaryHero(),
    ),
  ];

  @override
  ConsumerState<Step0SmokerTimerScreen> createState() =>
      _Step0SmokerTimerScreenState();
}

class _Step0SmokerTimerScreenState
    extends ConsumerState<Step0SmokerTimerScreen> {
  static const _pageAnimationDuration = Duration(milliseconds: 220);
  static const _pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 24);
  static const _maxContentWidth = 520.0;

  late final PageController _pageController;
  int _pageIndex = 0;

  /// Initializes the onboarding page controller.
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  /// Releases the onboarding page controller.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Advances to the next onboarding page or completes onboarding at the end.
  Future<void> _next() async {
    if (_pageIndex < Step0SmokerTimerScreen._pages.length - 1) {
      await _pageController.nextPage(
        duration: _pageAnimationDuration,
        curve: Curves.easeOut,
      );
      return;
    }

    await ref.read(appControllerProvider.notifier).completeOnboarding();
  }

  /// Skips onboarding and enters the main app flow immediately.
  Future<void> _skip() async {
    await ref.read(appControllerProvider.notifier).completeOnboarding();
  }

  /// Builds the onboarding pager with responsive content sections.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Scaffold(
      backgroundColor: ui.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: _pagePadding,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: Step0SmokerTimerScreen._pages
                    .map(
                      (page) => _OnboardingPage(
                        content: page,
                        onButtonTap: _next,
                        onSkipTap: _skip,
                        onStartTap: _skip,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
