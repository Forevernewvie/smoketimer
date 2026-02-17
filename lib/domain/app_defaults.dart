import 'models/app_meta.dart';
import 'models/user_settings.dart';

/// 정책값은 임의로 흩어 두지 않고 단일 위치에서 관리한다.
class AppDefaults {
  const AppDefaults._();

  static const int intervalMinutes = 45;
  static const int preAlertMinutes = 5;
  static const int allowedStartMinutes = 8 * 60;
  static const int allowedEndMinutes = 24 * 60;
  static const Set<int> activeWeekdays = {1, 2, 3, 4, 5};

  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const int scheduleCount = 12;

  static const List<int> intervalOptions = [30, 45, 60, 90];
  static const List<int> preAlertOptions = [0, 5, 10, 15];
  static const List<String> soundTypeOptions = ['default', 'silent'];

  static UserSettings defaultSettings() {
    return const UserSettings(
      intervalMinutes: intervalMinutes,
      preAlertMinutes: preAlertMinutes,
      repeatEnabled: true,
      allowedStartMinutes: allowedStartMinutes,
      allowedEndMinutes: allowedEndMinutes,
      activeWeekdays: activeWeekdays,
      use24Hour: true,
      ringReference: RingReference.lastSmoking,
      vibrationEnabled: true,
      soundType: 'default',
    );
  }

  static AppMeta defaultMeta() {
    return const AppMeta(hasCompletedOnboarding: false, lastSmokingAt: null);
  }
}
