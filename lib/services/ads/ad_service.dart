import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Standardized banner lifecycle states used by presentation and tests.
enum AdBannerStatus {
  idle,
  loading,
  loaded,
  failed,
  unsupported,
  misconfigured,
}

/// Immutable banner state snapshot exposed by [AdService].
class BannerAdState {
  /// Creates an ad state value object.
  const BannerAdState({
    this.status = AdBannerStatus.idle,
    this.banner,
    this.size = AdSize.banner,
    this.error,
  });

  /// Current lifecycle state.
  final AdBannerStatus status;

  /// Loaded ad instance, when available.
  final BannerAd? banner;

  /// Requested banner size.
  final AdSize size;

  /// Last known error object, if any.
  final Object? error;

  /// Returns true when the ad has completed loading and can be rendered.
  bool get isLoaded => status == AdBannerStatus.loaded && banner != null;

  /// Returns a copied state with selected fields changed.
  BannerAdState copyWith({
    AdBannerStatus? status,
    BannerAd? banner,
    bool clearBanner = false,
    AdSize? size,
    Object? error,
    bool clearError = false,
  }) {
    return BannerAdState(
      status: status ?? this.status,
      banner: clearBanner ? null : (banner ?? this.banner),
      size: size ?? this.size,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Signals an invalid or missing ad configuration.
class AdConfigurationException implements Exception {
  /// Creates a configuration exception with a user-facing reason.
  const AdConfigurationException(this.message);

  /// Human-readable error detail.
  final String message;

  @override
  String toString() => 'AdConfigurationException(message: $message)';
}

/// Banner ad service boundary used by UI and provider layer.
abstract class AdService {
  /// Live banner state stream exposed as [ValueListenable].
  ValueListenable<BannerAdState> get bannerState;

  /// Starts loading a banner ad when platform and configuration are valid.
  void loadMainBanner();

  /// Releases the currently loaded banner and resets transient state.
  void disposeBanner();

  /// Disposes service resources and listeners.
  void disposeService();
}

/// No-op implementation for tests and unsupported runtime environments.
class NoopAdService implements AdService {
  /// Creates a no-op service in an `unsupported` state.
  NoopAdService()
    : _state = ValueNotifier<BannerAdState>(
        const BannerAdState(status: AdBannerStatus.unsupported),
      );

  final ValueNotifier<BannerAdState> _state;

  @override
  ValueListenable<BannerAdState> get bannerState => _state;

  @override
  void loadMainBanner() {}

  @override
  void disposeBanner() {
    _state.value = const BannerAdState(status: AdBannerStatus.unsupported);
  }

  @override
  void disposeService() {
    _state.dispose();
  }
}
