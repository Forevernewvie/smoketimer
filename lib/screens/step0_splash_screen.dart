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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const _SplashA3Card(),
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

class _SplashA3Card extends StatelessWidget {
  const _SplashA3Card();

  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SurfaceCard(
          color: ui.surface,
          strokeColor: ui.border,
          cornerRadius: SmokeUiRadius.lg,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusChip(
                text: '준비 중',
                icon: Icons.timer_outlined,
                foregroundColor: SmokeUiPalette.accentDark,
                backgroundColor: SmokeUiPalette.accentSoft,
                borderColor: Color(0xFFFFC89E),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 84,
                    height: 84,
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
                  const SizedBox(width: SmokeUiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '흡연 타이머',
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: SmokeUiSpacing.xs),
                        Text(
                          '기록과 알림 상태를 불러오고 있어요.',
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SmokeUiSpacing.lg),
              SurfaceCard(
                color: ui.surfaceAlt,
                strokeColor: ui.border,
                cornerRadius: SmokeUiRadius.md,
                padding: const EdgeInsets.all(SmokeUiSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(text: '불러오는 중'),
                    const SizedBox(height: SmokeUiSpacing.sm),
                    Text(
                      '마지막 기록, 알림 설정, 화면 구성을 안전하게 준비합니다.',
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: SmokeUiSpacing.md),
                    _AnimatedSplashLoadingBar(reduceMotion: reduceMotion),
                    const SizedBox(height: SmokeUiSpacing.sm),
                    Text(
                      '시작 준비 중',
                      style: TextStyle(
                        color: ui.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SmokeUiSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: ui.textMuted),
                  const SizedBox(width: SmokeUiSpacing.xs),
                  Expanded(
                    child: Text(
                      '진입 직후에도 핵심 상태와 기록 동작이 먼저 보이도록 최소한만 불러옵니다.',
                      style: TextStyle(
                        color: ui.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedSplashLoadingBar extends StatefulWidget {
  const _AnimatedSplashLoadingBar({this.reduceMotion = false});

  static const trackWidth = 136.0;
  static const barHeight = 8.0;
  static const segmentWidth = 56.0;

  final bool reduceMotion;

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
    );
    if (!widget.reduceMotion) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.32;
    }
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant _AnimatedSplashLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion == widget.reduceMotion) {
      return;
    }
    if (widget.reduceMotion) {
      _controller
        ..stop()
        ..value = 0.32;
    } else {
      _controller.repeat(reverse: true);
    }
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
                final progress = widget.reduceMotion ? 0.32 : _t.value;
                return Transform.translate(
                  offset: Offset(travel * progress, 0),
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
                      gradient: const LinearGradient(
                        colors: [
                          SmokeUiPalette.accent,
                          SmokeUiPalette.accentDark,
                        ],
                      ),
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
