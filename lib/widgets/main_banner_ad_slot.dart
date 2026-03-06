import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads/ad_service.dart';
import 'pen_design_widgets.dart';

/// Bottom-slot banner renderer with graceful fallback behaviors.
class MainBannerAdSlot extends StatelessWidget {
  /// Creates the banner slot widget.
  const MainBannerAdSlot({super.key, required this.adService});

  static const double _bannerPlaceholderHeight = 50;

  /// Backing ad service dependency.
  final AdService adService;

  /// Rebuilds slot whenever ad state transitions.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ValueListenableBuilder<BannerAdState>(
      valueListenable: adService.bannerState,
      builder: (context, state, child) {
        final Widget slot;
        if (state.status == AdBannerStatus.loading) {
          slot = Container(
            key: const Key('main_banner_placeholder'),
            height: _bannerPlaceholderHeight,
            decoration: BoxDecoration(
              color: ui.surfaceAlt,
              border: Border(top: BorderSide(color: ui.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              '광고 영역 준비 중',
              style: TextStyle(
                color: ui.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else {
          final banner = state.banner;
          if (state.isLoaded && banner != null) {
            slot = Container(
              key: const Key('main_banner_slot'),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ui.surfaceAlt,
                border: Border(top: BorderSide(color: ui.border)),
              ),
              child: SizedBox(
                width: state.size.width.toDouble(),
                height: state.size.height.toDouble(),
                child: AdWidget(
                  key: const Key('main_banner_loaded'),
                  ad: banner,
                ),
              ),
            );
          } else {
            slot = const SizedBox(key: Key('main_banner_hidden'), height: 0);
          }
        }

        return AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: slot,
        );
      },
    );
  }
}
