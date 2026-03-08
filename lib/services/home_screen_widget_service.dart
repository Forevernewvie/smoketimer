import 'package:flutter/foundation.dart';

import '../domain/models/home_widget_snapshot.dart';
import '../presentation/state/app_config.dart';
import 'home_widget_platform_adapter.dart';
import 'logging/app_logger.dart';

/// Synchronizes Flutter app state into native Android and iOS home screen widgets.
class HomeScreenWidgetService {
  /// Creates a widget sync service using the injected platform adapter.
  HomeScreenWidgetService({
    required HomeWidgetPlatformAdapter platformAdapter,
    required AppConfig config,
  }) : _platformAdapter = platformAdapter,
       _config = config;

  final HomeWidgetPlatformAdapter _platformAdapter;
  final AppConfig _config;
  static const _logger = AppLogger(namespace: 'home-widget-service');

  bool _initialized = false;
  HomeWidgetSnapshot? _lastSnapshot;

  /// Initializes widget sharing prerequisites such as the iOS App Group.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _platformAdapter.setAppGroupId(_config.homeWidget.iOSAppGroupId);
      }
      _initialized = true;
    } catch (error, stackTrace) {
      _logger.error(
        'failed to initialize home widget integration',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Saves a snapshot and requests a native widget refresh when values changed.
  Future<void> syncSnapshot(HomeWidgetSnapshot snapshot) async {
    if (_lastSnapshot == snapshot) {
      return;
    }

    await initialize();
    try {
      final storageMap = snapshot.toStorageMap();
      for (final entry in storageMap.entries) {
        await _platformAdapter.saveString(entry.key, entry.value);
      }
      await _platformAdapter.updateWidget(
        androidName: _config.homeWidget.androidProviderName,
        qualifiedAndroidName: _config.homeWidget.androidQualifiedProviderName,
        iOSName: _config.homeWidget.iOSWidgetKind,
      );
      _lastSnapshot = snapshot;
      _logger.info('home widget snapshot synced');
    } catch (error, stackTrace) {
      _logger.error(
        'failed to sync home widget snapshot',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
