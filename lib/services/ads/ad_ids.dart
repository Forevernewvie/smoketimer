import 'package:flutter/foundation.dart';

/// Centralized AdMob identifiers and environment-key mapping.
///
/// Production IDs are injected via `--dart-define` to avoid hardcoded values.
/// Debug builds always use Google's official test ad units.
class AdIds {
  const AdIds._();

  /// Android release banner ID key: `--dart-define=ADMOB_ANDROID_BANNER_ID=...`
  static const String _androidReleaseBannerEnv = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: '',
  );

  /// iOS release banner ID key: `--dart-define=ADMOB_IOS_BANNER_ID=...`
  static const String _iosReleaseBannerEnv = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: '',
  );

  /// Optional iOS app ID key: `--dart-define=ADMOB_IOS_APP_ID=...`
  static const String iosAppIdFromEnv = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: '',
  );

  /// Google-provided Android test banner ID.
  static const String _androidTestBanner =
      'ca-app-pub-3940256099942544/6300978111';

  /// Google-provided iOS test banner ID.
  static const String _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';

  /// Returns whether this runtime platform can render mobile banner ads.
  static bool supportsPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  /// Returns a human-readable ad mode label used in structured logs.
  static String bannerModeLabel({required bool isReleaseMode}) {
    return isReleaseMode ? 'prod' : 'test';
  }

  /// Returns banner unit ID for the given platform and build mode.
  ///
  /// - Debug/Profile: always returns a Google test unit.
  /// - Release: returns env-configured unit or `null` when not configured.
  static String? bannerAdUnitId({
    required TargetPlatform platform,
    required bool isReleaseMode,
  }) {
    if (!isReleaseMode) {
      return _testBannerAdUnitId(platform);
    }

    final configuredId = _releaseBannerAdUnitId(platform);
    if (configuredId == null || configuredId.trim().isEmpty) {
      return null;
    }
    return configuredId.trim();
  }

  /// Returns the current runtime banner unit ID with optional overrides.
  static String? currentBannerAdUnitId({
    TargetPlatform? platform,
    bool? isReleaseMode,
  }) {
    return bannerAdUnitId(
      platform: platform ?? defaultTargetPlatform,
      isReleaseMode: isReleaseMode ?? kReleaseMode,
    );
  }

  /// Returns a Google test ID for non-release builds.
  static String _testBannerAdUnitId(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return _androidTestBanner;
      case TargetPlatform.iOS:
        return _iosTestBanner;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _androidTestBanner;
    }
  }

  /// Returns a configured release ID from environment, if present.
  static String? _releaseBannerAdUnitId(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return _androidReleaseBannerEnv;
      case TargetPlatform.iOS:
        return _iosReleaseBannerEnv;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }
}
