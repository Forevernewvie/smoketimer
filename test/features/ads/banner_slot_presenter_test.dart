import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:smoke_timer/services/ads/ad_service.dart';
import 'package:smoke_timer/widgets/main_banner_ad_slot_presenter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loading state keeps placeholder visible with shared tokens', () {
    const state = BannerAdState(status: AdBannerStatus.loading);

    final presentation = MainBannerAdSlotPresenter.fromState(state);

    expect(presentation.kind, MainBannerAdSlotKind.placeholder);
    expect(presentation.message, MainBannerAdSlotTokens.placeholderMessage);
    expect(presentation.height, MainBannerAdSlotTokens.placeholderHeight);
  });

  test('failed and misconfigured states collapse the slot', () {
    const failedState = BannerAdState(status: AdBannerStatus.failed);
    const misconfiguredState = BannerAdState(
      status: AdBannerStatus.misconfigured,
    );

    final failedPresentation = MainBannerAdSlotPresenter.fromState(failedState);
    final misconfiguredPresentation = MainBannerAdSlotPresenter.fromState(
      misconfiguredState,
    );

    expect(failedPresentation.kind, MainBannerAdSlotKind.hidden);
    expect(misconfiguredPresentation.kind, MainBannerAdSlotKind.hidden);
  });

  test('loaded state without banner instance is hidden for safety', () {
    const state = BannerAdState(status: AdBannerStatus.loaded);

    final presentation = MainBannerAdSlotPresenter.fromState(state);

    expect(presentation.kind, MainBannerAdSlotKind.hidden);
  });

  test('loaded state exposes banner size when an instance exists', () {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: 'test-banner',
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
    addTearDown(banner.dispose);

    final state = BannerAdState(status: AdBannerStatus.loaded, banner: banner);

    final presentation = MainBannerAdSlotPresenter.fromState(state);

    expect(presentation.kind, MainBannerAdSlotKind.loaded);
    expect(presentation.bannerWidth, AdSize.banner.width.toDouble());
    expect(presentation.bannerHeight, AdSize.banner.height.toDouble());
  });
}
