import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads/ad_service.dart';

/// Bottom-slot banner renderer with graceful fallback behaviors.
class MainBannerAdSlot extends StatelessWidget {
  /// Creates the banner slot widget.
  const MainBannerAdSlot({super.key, required this.adService});

  static const double _bannerPlaceholderHeight = 50;
  static const Color _slotBackgroundColor = Color(0xFFF7F9FC);

  /// Backing ad service dependency.
  final AdService adService;

  /// Rebuilds slot whenever ad state transitions.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BannerAdState>(
      valueListenable: adService.bannerState,
      builder: (context, state, child) {
        if (state.status == AdBannerStatus.loading) {
          return const SizedBox(
            key: Key('main_banner_placeholder'),
            height: _bannerPlaceholderHeight,
          );
        }

        final banner = state.banner;
        if (state.isLoaded && banner != null) {
          return Container(
            key: const Key('main_banner_slot'),
            alignment: Alignment.center,
            color: _slotBackgroundColor,
            child: SizedBox(
              width: state.size.width.toDouble(),
              height: state.size.height.toDouble(),
              child: AdWidget(key: const Key('main_banner_loaded'), ad: banner),
            ),
          );
        }

        return const SizedBox(key: Key('main_banner_hidden'), height: 0);
      },
    );
  }
}
