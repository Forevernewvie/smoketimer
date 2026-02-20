import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../logging/app_logger.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

/// Concrete [AdService] implementation backed by `google_mobile_ads`.
class AdMobService implements AdService {
  /// Creates an AdMob service with retry policy and runtime overrides.
  AdMobService({
    required AppLogger logger,
    Duration retryBaseDelay = const Duration(seconds: 2),
    int maxRetryCount = 3,
    TargetPlatform? platformOverride,
    bool? releaseModeOverride,
  }) : _logger = logger,
       _retryBaseDelay = retryBaseDelay,
       _maxRetryCount = maxRetryCount,
       _platformOverride = platformOverride,
       _releaseModeOverride = releaseModeOverride;

  static const String _selfClickPolicyWarning =
      'policy: do not tap ads on your own test devices.';

  final AppLogger _logger;
  final Duration _retryBaseDelay;
  final int _maxRetryCount;
  final TargetPlatform? _platformOverride;
  final bool? _releaseModeOverride;
  final ValueNotifier<BannerAdState> _state = ValueNotifier<BannerAdState>(
    const BannerAdState(),
  );

  BannerAd? _banner;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _loading = false;
  bool _disposed = false;

  @override
  ValueListenable<BannerAdState> get bannerState => _state;

  /// Starts banner loading if not already loaded and platform is supported.
  @override
  void loadMainBanner() {
    if (_disposed || _loading || _banner != null) {
      return;
    }

    final platform = _platformOverride ?? defaultTargetPlatform;
    if (!AdIds.supportsPlatform(platform)) {
      _logger.info('banner skipped: unsupported platform ($platform)');
      _updateState(const BannerAdState(status: AdBannerStatus.unsupported));
      return;
    }

    _loadBanner();
  }

  /// Loads a banner and wires success/failure callbacks.
  void _loadBanner() {
    if (_disposed) {
      return;
    }

    _retryTimer?.cancel();
    _loading = true;
    _updateState(
      _state.value.copyWith(status: AdBannerStatus.loading, clearError: true),
    );

    final isReleaseMode = _releaseModeOverride ?? kReleaseMode;
    final mode = AdIds.bannerModeLabel(isReleaseMode: isReleaseMode);
    _logger.info('loading main banner ($mode)');
    if (kDebugMode) {
      _logger.debug(_selfClickPolicyWarning);
    }

    final adUnitId = AdIds.currentBannerAdUnitId(
      platform: _platformOverride,
      isReleaseMode: _releaseModeOverride,
    );
    if (adUnitId == null || adUnitId.trim().isEmpty) {
      _loading = false;
      const error = AdConfigurationException(
        'Release banner ad unit ID is missing. Provide --dart-define=ADMOB_*_BANNER_ID.',
      );
      _logger.warning('banner misconfigured', error: error);
      _updateState(
        _state.value.copyWith(
          status: AdBannerStatus.misconfigured,
          clearBanner: true,
          error: error,
        ),
      );
      return;
    }

    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          final loadedBanner = ad as BannerAd;
          _loading = false;
          _retryAttempt = 0;
          _banner = loadedBanner;
          _logger.info('banner loaded successfully');
          _updateState(
            BannerAdState(
              status: AdBannerStatus.loaded,
              banner: loadedBanner,
              size: loadedBanner.size,
            ),
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
          _loading = false;
          _logger.warning('banner load failed', error: error);
          _updateState(
            _state.value.copyWith(
              status: AdBannerStatus.failed,
              clearBanner: true,
              error: error,
            ),
          );
          _scheduleRetry();
        },
      ),
    );

    _banner = banner;
    banner.load();
  }

  /// Schedules bounded exponential-backoff retry to avoid aggressive loops.
  void _scheduleRetry() {
    if (_disposed || _retryAttempt >= _maxRetryCount) {
      return;
    }

    final multiplier = 1 << _retryAttempt;
    final retryDelay = _retryBaseDelay * multiplier;
    _retryAttempt += 1;
    _logger.info('banner retry scheduled in ${retryDelay.inSeconds}s');
    _retryTimer = Timer(retryDelay, _loadBanner);
  }

  /// Pushes next state while respecting disposal state.
  void _updateState(BannerAdState next) {
    if (_disposed) {
      return;
    }
    _state.value = next;
  }

  /// Clears banner resources and resets state to idle.
  @override
  void disposeBanner() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _loading = false;
    _retryAttempt = 0;
    _banner?.dispose();
    _banner = null;
    _updateState(const BannerAdState(status: AdBannerStatus.idle));
  }

  /// Disposes all held resources, including notifier listeners.
  @override
  void disposeService() {
    if (_disposed) {
      return;
    }
    disposeBanner();
    _disposed = true;
    _state.dispose();
  }
}
