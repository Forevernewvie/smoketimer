part of 'step0_smoker_timer_screen.dart';

/// Immutable content model for a single onboarding page.
class _OnboardingPageContent {
  const _OnboardingPageContent({
    required this.index,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.hero,
  });

  final int index;
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final Widget hero;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.content,
    required this.onButtonTap,
    required this.onSkipTap,
    required this.onStartTap,
  });

  final _OnboardingPageContent content;
  final VoidCallback onButtonTap;
  final VoidCallback onSkipTap;
  final VoidCallback onStartTap;

  /// Builds a single onboarding page with responsive copy and actions.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 730 || textScale > 1.25;
        final titleSize = _resolveTitleSize(
          maxWidth: constraints.maxWidth,
          textScale: textScale,
        );
        final accentColor = _resolveAccentColor(content.index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OnboardingHeader(pageIndex: content.index, onSkipTap: onSkipTap),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                physics: compact
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content.hero,
                    const SizedBox(height: 14),
                    Text(
                      content.title,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: titleSize,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content.description,
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OnboardingFeatureCard(
                      features: content.features,
                      accentColor: accentColor,
                      isFinalPage: content.index == 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PageDots(activeIndex: content.index),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              text: content.buttonText,
              icon: content.index == 2
                  ? Icons.arrow_forward_rounded
                  : Icons.chevron_right_rounded,
              height: 48,
              color: SmokeUiPalette.accent,
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              onTap: onButtonTap,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              text: '앱 시작',
              icon: Icons.play_arrow_rounded,
              height: 48,
              radius: 24,
              foregroundColor: ui.textPrimary,
              backgroundColor: compact ? ui.surface : ui.surfaceAlt,
              borderColor: ui.border,
              onTap: onStartTap,
            ),
          ],
        );
      },
    );
  }

  /// Resolves the responsive title size without letting scale grow unstable.
  double _resolveTitleSize({
    required double maxWidth,
    required double textScale,
  }) {
    final baseTitleSize = maxWidth < 360 ? 28.0 : 30.0;
    final scaledTitleSize =
        baseTitleSize / textScale.clamp(1.0, 1.35).toDouble();
    return scaledTitleSize.clamp(22.0, 30.0).toDouble();
  }

  /// Maps page index to its supporting accent color.
  Color _resolveAccentColor(int index) {
    return switch (index) {
      0 => const Color(0xFF1D4ED8),
      1 => SmokeUiPalette.accentDark,
      _ => SmokeUiPalette.mint,
    };
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.pageIndex, required this.onSkipTap});

  final int pageIndex;
  final VoidCallback onSkipTap;

  /// Renders the onboarding progress label and skip affordance.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${pageIndex + 1}/3',
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
    );
  }
}

class _OnboardingFeatureCard extends StatelessWidget {
  const _OnboardingFeatureCard({
    required this.features,
    required this.accentColor,
    required this.isFinalPage,
  });

  final List<String> features;
  final Color accentColor;
  final bool isFinalPage;

  /// Shows the feature summary list for the current onboarding page.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: '이 화면에서 할 수 있는 것'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SurfaceCard(
            color: ui.surfaceAlt,
            strokeColor: ui.border,
            padding: const EdgeInsets.all(14),
            cornerRadius: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(features.length, (featureIndex) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: featureIndex == features.length - 1 ? 0 : 8,
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
                    isFinalPage
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
    );
  }
}
