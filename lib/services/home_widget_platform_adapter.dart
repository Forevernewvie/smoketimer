import 'package:home_widget/home_widget.dart';

/// Abstracts the `home_widget` plugin for easier testing and fallback handling.
abstract class HomeWidgetPlatformAdapter {
  /// Sets the iOS App Group used for sharing widget data with the extension.
  Future<void> setAppGroupId(String appGroupId);

  /// Saves a single string value into the platform widget storage.
  Future<void> saveString(String key, String value);

  /// Triggers a native widget refresh on both Android and iOS.
  Future<void> updateWidget({
    required String androidName,
    required String qualifiedAndroidName,
    required String iOSName,
  });
}

/// Production adapter backed by the `home_widget` plugin package.
class HomeWidgetPackageAdapter implements HomeWidgetPlatformAdapter {
  /// Creates the default adapter used in app runtime.
  const HomeWidgetPackageAdapter();

  @override
  Future<void> saveString(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<void> setAppGroupId(String appGroupId) async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  @override
  Future<void> updateWidget({
    required String androidName,
    required String qualifiedAndroidName,
    required String iOSName,
  }) async {
    await HomeWidget.updateWidget(
      name: androidName,
      qualifiedAndroidName: qualifiedAndroidName,
      iOSName: iOSName,
    );
  }
}
