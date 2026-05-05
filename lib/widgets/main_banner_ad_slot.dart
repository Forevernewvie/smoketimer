import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads/ad_service.dart';
import '../services/logging/app_logger.dart';
import 'pen_design_widgets.dart';
import 'main_banner_ad_slot_presenter.dart';

/// Bottom-slot banner renderer for the resolved ad lifecycle state.
class MainBannerAdSlot extends StatelessWidget {
  /// Creates the banner slot widget.
  const MainBannerAdSlot({
    super.key,
    required this.adService,
    AppLogger logger = const AppLogger(namespace: 'main-banner-slot'),
  }) : _logger = logger;

  /// Backing ad service dependency.
  final AdService adService;

  final AppLogger _logger;

  /// Rebuilds slot whenever ad state transitions.
  @override
  Widget build(BuildContext context) {
    final ui = SmokeUiTheme.of(context);

    return ValueListenableBuilder<BannerAdState>(
      valueListenable: adService.bannerState,
      builder: (context, state, child) {
        final presentation = MainBannerAdSlotPresenter.fromState(state);
        return _buildSlot(
          context,
          state: state,
          presentation: presentation,
          ui: ui,
        );
      },
    );
  }

  /// Builds the slot body from the already-resolved presentation model.
  Widget _buildSlot(
    BuildContext context, {
    required BannerAdState state,
    required MainBannerAdSlotPresentation presentation,
    required SmokeUiTheme ui,
  }) {
    switch (presentation.kind) {
      case MainBannerAdSlotKind.placeholder:
        return Container(
          key: const Key('main_banner_placeholder'),
          color: ui.background,
          padding: const EdgeInsets.fromLTRB(
            MainBannerAdSlotTokens.horizontalPadding,
            MainBannerAdSlotTokens.verticalPadding,
            MainBannerAdSlotTokens.horizontalPadding,
            MainBannerAdSlotTokens.verticalPadding,
          ),
          child: Container(
            height: presentation.height,
            decoration: BoxDecoration(
              color: ui.surfaceAlt,
              borderRadius: BorderRadius.circular(
                MainBannerAdSlotTokens.shellRadius,
              ),
              border: Border.all(color: ui.border),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MainBannerAdSlotTokens.horizontalPadding,
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              presentation.message ?? MainBannerAdSlotTokens.placeholderMessage,
              style: TextStyle(
                color: ui.textMuted,
                fontSize: MainBannerAdSlotTokens.placeholderFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case MainBannerAdSlotKind.loaded:
        final banner = state.banner;
        if (banner == null) {
          _logger.warning(
            'loaded banner slot requested without banner instance',
            error: state.error,
          );
          return const SizedBox(key: Key('main_banner_hidden'), height: 0);
        }
        return Container(
          key: const Key('main_banner_slot'),
          color: ui.background,
          padding: const EdgeInsets.fromLTRB(
            MainBannerAdSlotTokens.horizontalPadding,
            MainBannerAdSlotTokens.verticalPadding,
            MainBannerAdSlotTokens.horizontalPadding,
            MainBannerAdSlotTokens.verticalPadding,
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ui.surfaceAlt,
              borderRadius: BorderRadius.circular(
                MainBannerAdSlotTokens.shellRadius,
              ),
              border: Border.all(color: ui.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                MainBannerAdSlotTokens.shellRadius - 2,
              ),
              child: SizedBox(
                width: presentation.bannerWidth,
                height: presentation.bannerHeight,
                child: AdWidget(
                  key: const Key('main_banner_loaded'),
                  ad: banner,
                ),
              ),
            ),
          ),
        );
      case MainBannerAdSlotKind.hidden:
        return const SizedBox(key: Key('main_banner_hidden'), height: 0);
    }
  }
}
