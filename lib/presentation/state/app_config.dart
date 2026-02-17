import '../../domain/app_defaults.dart';

class AppConfig {
  const AppConfig({
    this.splashDuration = AppDefaults.splashDuration,
    this.scheduleCount = AppDefaults.scheduleCount,
  });

  final Duration splashDuration;
  final int scheduleCount;
}
