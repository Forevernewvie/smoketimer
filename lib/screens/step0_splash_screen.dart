import 'package:flutter/material.dart';

import '../widgets/pen_design_widgets.dart';

class Step0SplashScreen extends StatelessWidget {
  const Step0SplashScreen({super.key});

  static const routeName = '/step0-splash';

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Scaffold(
      backgroundColor: ui.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: const _SplashA3Card(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashA3Card extends StatelessWidget {
  const _SplashA3Card();

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 92,
          height: 92,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SmokeUiPalette.accentDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restart_alt_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '흡연 타이머',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '마지막 흡연 후 경과 시간 표시',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        const _AnimatedSplashLoadingBar(),
        const SizedBox(height: 14),
        Text(
          '시작 준비 중',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnimatedSplashLoadingBar extends StatefulWidget {
  const _AnimatedSplashLoadingBar();

  static const trackWidth = 120.0;
  static const barHeight = 6.0;
  static const segmentWidth = 58.0;

  @override
  State<_AnimatedSplashLoadingBar> createState() =>
      _AnimatedSplashLoadingBarState();
}

class _AnimatedSplashLoadingBarState extends State<_AnimatedSplashLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return SizedBox(
      width: _AnimatedSplashLoadingBar.trackWidth,
      height: _AnimatedSplashLoadingBar.barHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ui.border,
          borderRadius: BorderRadius.circular(999),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final travel =
                (constraints.maxWidth - _AnimatedSplashLoadingBar.segmentWidth)
                    .clamp(0.0, double.infinity);

            return AnimatedBuilder(
              animation: _t,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(travel * _t.value, 0),
                  child: child,
                );
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  key: const Key('splash_loading_segment'),
                  width: _AnimatedSplashLoadingBar.segmentWidth,
                  height: _AnimatedSplashLoadingBar.barHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SmokeUiPalette.accentDark,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
