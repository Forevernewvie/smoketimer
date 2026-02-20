import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/ad_service.dart';
import '../../services/ads/admob_service.dart';
import '../../services/logging/app_logger.dart';

/// Logger used by the ads subsystem for consistent structured logs.
final adLoggerProvider = Provider<AppLogger>((ref) {
  return const AppLogger(namespace: 'ads');
});

/// Ad service provider with explicit lifecycle disposal.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdMobService(logger: ref.watch(adLoggerProvider));
  ref.onDispose(service.disposeService);
  return service;
});
