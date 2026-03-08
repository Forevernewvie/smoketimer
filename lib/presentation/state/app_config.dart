import '../../domain/app_defaults.dart';

class HomeWidgetConfig {
  const HomeWidgetConfig({
    required this.androidProviderName,
    required this.androidQualifiedProviderName,
    required this.iOSWidgetKind,
    required this.iOSAppGroupId,
  });

  final String androidProviderName;
  final String androidQualifiedProviderName;
  final String iOSWidgetKind;
  final String iOSAppGroupId;
}

class MonetizationConfig {
  const MonetizationConfig({
    this.enableBannerAds = true,
    this.showBannerOnHomeTab = false,
    this.showBannerOnRecordTab = true,
    this.showBannerOnSettingsTab = true,
  });

  final bool enableBannerAds;
  final bool showBannerOnHomeTab;
  final bool showBannerOnRecordTab;
  final bool showBannerOnSettingsTab;

  /// Returns whether the banner should be shown for the selected main tab.
  bool shouldShowBannerForTab(int tabIndex) {
    return switch (tabIndex) {
      0 => enableBannerAds && showBannerOnHomeTab,
      1 => enableBannerAds && showBannerOnRecordTab,
      2 => enableBannerAds && showBannerOnSettingsTab,
      _ => false,
    };
  }
}

class AppConfig {
  const AppConfig({
    this.splashDuration = AppDefaults.splashDuration,
    this.scheduleCount = AppDefaults.scheduleCount,
    this.homeWidget = const HomeWidgetConfig(
      androidProviderName: 'SmokeTimerHomeWidgetProvider',
      androidQualifiedProviderName:
          'com.forevernewvie.smoketimer.SmokeTimerHomeWidgetProvider',
      iOSWidgetKind: 'SmokeTimerWidget',
      iOSAppGroupId: 'group.com.example.smokeTimer.widget',
    ),
    this.monetization = const MonetizationConfig(),
  });

  final Duration splashDuration;
  final int scheduleCount;
  final HomeWidgetConfig homeWidget;
  final MonetizationConfig monetization;
}
