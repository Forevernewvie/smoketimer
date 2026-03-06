import '../services/ads/ad_service.dart';

/// Shared visual tokens for the bottom banner slot.
class MainBannerAdSlotTokens {
  /// Prevents accidental instantiation of this token holder.
  const MainBannerAdSlotTokens._();

  /// Fixed slot height that matches the current banner placeholder contract.
  static const double placeholderHeight = 50;

  /// Horizontal padding for placeholder content.
  static const double horizontalPadding = 16;

  /// Font size used for the auxiliary placeholder label.
  static const double placeholderFontSize = 11;

  /// Expand/collapse animation duration for slot height changes.
  static const Duration expandAnimationDuration = Duration(milliseconds: 180);

  /// Copy shown while the banner lifecycle is still resolving.
  static const String placeholderMessage = '광고 영역 준비 중';
}

/// Describes how the bottom banner slot should render for a given ad state.
class MainBannerAdSlotPresentation {
  /// Creates a render presentation for the bottom ad slot.
  const MainBannerAdSlotPresentation._({
    required this.kind,
    this.height = 0,
    this.message,
    this.bannerWidth = 0,
    this.bannerHeight = 0,
  });

  /// Builds a placeholder presentation for banner loading.
  const MainBannerAdSlotPresentation.placeholder({
    required String message,
    required double height,
  }) : this._(
         kind: MainBannerAdSlotKind.placeholder,
         height: height,
         message: message,
       );

  /// Builds a presentation for a successfully loaded banner.
  const MainBannerAdSlotPresentation.loaded({
    required double bannerWidth,
    required double bannerHeight,
  }) : this._(
         kind: MainBannerAdSlotKind.loaded,
         bannerWidth: bannerWidth,
         bannerHeight: bannerHeight,
       );

  /// Builds a collapsed presentation for hidden or non-renderable states.
  const MainBannerAdSlotPresentation.hidden()
    : this._(kind: MainBannerAdSlotKind.hidden);

  /// Slot rendering mode resolved from banner state.
  final MainBannerAdSlotKind kind;

  /// Reserved vertical height for placeholder rendering.
  final double height;

  /// Placeholder status copy shown during loading.
  final String? message;

  /// Rendered banner width when an ad is ready.
  final double bannerWidth;

  /// Rendered banner height when an ad is ready.
  final double bannerHeight;

  /// Returns true when the slot should reserve visible space.
  bool get isVisible => kind != MainBannerAdSlotKind.hidden;
}

/// Small render-mode enum that keeps UI branching explicit and testable.
enum MainBannerAdSlotKind { hidden, placeholder, loaded }

/// Pure mapper that converts ad lifecycle state into a slot presentation model.
class MainBannerAdSlotPresenter {
  /// Prevents accidental instantiation of this pure utility class.
  const MainBannerAdSlotPresenter._();

  /// Resolves the render policy for the provided [BannerAdState].
  ///
  /// Loading keeps the slot visible to avoid sudden layout jumps.
  /// Failed, unsupported, or misconfigured states intentionally collapse the
  /// slot so no internal error details leak into the UI.
  static MainBannerAdSlotPresentation fromState(BannerAdState state) {
    switch (state.status) {
      case AdBannerStatus.loading:
        return const MainBannerAdSlotPresentation.placeholder(
          message: MainBannerAdSlotTokens.placeholderMessage,
          height: MainBannerAdSlotTokens.placeholderHeight,
        );
      case AdBannerStatus.loaded:
        if (state.banner == null) {
          return const MainBannerAdSlotPresentation.hidden();
        }
        return MainBannerAdSlotPresentation.loaded(
          bannerWidth: state.size.width.toDouble(),
          bannerHeight: state.size.height.toDouble(),
        );
      case AdBannerStatus.idle:
      case AdBannerStatus.failed:
      case AdBannerStatus.unsupported:
      case AdBannerStatus.misconfigured:
        return const MainBannerAdSlotPresentation.hidden();
    }
  }
}
