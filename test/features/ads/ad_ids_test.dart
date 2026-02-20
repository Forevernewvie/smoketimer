import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/services/ads/ad_ids.dart';

void main() {
  group('AdIds.bannerAdUnitId', () {
    test('uses google test id in debug mode', () {
      final adUnitId = AdIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        isReleaseMode: false,
      );

      expect(adUnitId, 'ca-app-pub-3940256099942544/6300978111');
    });

    test('returns null in release mode when no env unit is configured', () {
      final adUnitId = AdIds.bannerAdUnitId(
        platform: TargetPlatform.android,
        isReleaseMode: true,
      );

      expect(adUnitId, isNull);
    });

    test('returns null on iOS release when no env unit is configured', () {
      final adUnitId = AdIds.bannerAdUnitId(
        platform: TargetPlatform.iOS,
        isReleaseMode: true,
      );

      expect(adUnitId, isNull);
    });
  });
}
