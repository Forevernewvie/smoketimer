import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smoke_timer/services/ads/ad_service.dart';
import 'package:smoke_timer/services/ads/admob_service.dart';
import 'package:smoke_timer/services/logging/app_logger.dart';

void main() {
  test('admob service transitions to misconfigured state without throwing '
      'when release unit id is missing', () {
    final service = AdMobService(
      logger: const AppLogger(namespace: 'ads-test'),
      platformOverride: TargetPlatform.android,
      releaseModeOverride: true,
    );
    addTearDown(service.disposeService);

    expect(() => service.loadMainBanner(), returnsNormally);
    expect(service.bannerState.value.status, AdBannerStatus.misconfigured);
    expect(service.bannerState.value.error, isA<AdConfigurationException>());
  });
}
