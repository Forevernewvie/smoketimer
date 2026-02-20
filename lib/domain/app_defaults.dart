import 'models/app_meta.dart';
import 'models/user_settings.dart';

/// 정책값은 임의로 흩어 두지 않고 단일 위치에서 관리한다.
class AppDefaults {
  const AppDefaults._();

  /// Time conversion constants used to avoid magic numbers.
  static const int minutesPerHour = 60;
  static const int hoursPerDay = 24;
  static const int minutesPerDay = hoursPerDay * minutesPerHour;
  static const int secondsPerMinute = 60;
  static const int secondsPerHour = minutesPerHour * secondsPerMinute;
  static const int daysPerWeek = 7;

  /// Interval picker policy:
  /// - Allowed range: 30 minutes .. 4 hours
  /// - Slider granularity: 5 minutes (UX choice; adjust if product decides)
  static const int minIntervalMinutes = 30;
  static const int maxIntervalMinutes = 4 * minutesPerHour;
  static const int intervalStepMinutes = 5;

  static const int intervalMinutes = 45;
  static const int preAlertMinutes = 5;
  static const int allowedStartMinutes = 8 * minutesPerHour;
  static const int allowedEndMinutes = minutesPerDay;
  static const Set<int> activeWeekdays = {1, 2, 3, 4, 5};

  /// Allowed notification window picker policy.
  static const int allowedWindowMinMinutes = 0;
  static const int allowedWindowMaxMinutes = minutesPerDay;
  static const int allowedWindowStepMinutes = 15;

  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const int scheduleCount = 12;
  static const int scheduledAlertIdBase = 10_000;
  static const int schedulerBuildGuardLimit = 10_000;
  static const int schedulerAlignGuardLimit = 20_000;
  static const int testNotificationId = 900001;
  static const String alertNotificationTitle = '흡연 타이머';
  static const String alertNotificationBody = '다음 흡연 간격 알림입니다.';
  static const String testNotificationTitle = '흡연 타이머 테스트';
  static const String testNotificationBody = '테스트 알림이 정상 동작했습니다.';

  static const List<int> intervalOptions = [30, 45, 60, 90];
  static const List<int> preAlertOptions = [0, 5, 10, 15];
  static const List<String> soundTypeOptions = ['default', 'silent'];

  /// Cost tracking policy:
  /// - `packPrice` is interpreted as local currency amount for one pack.
  /// - Current product policy recomputes historical spend using current price.
  static const double defaultPackPrice = 0;
  static const double minPackPrice = 100;
  static const double maxPackPrice = 200000;
  static const int defaultCigarettesPerPack = 20;
  static const int minCigarettesPerPack = 1;
  static const int maxCigarettesPerPack = 60;
  static const String defaultCurrencyCode = 'KRW';
  static const String defaultCurrencySymbol = '₩';
  static const List<String> currencyCodeOptions = ['KRW', 'USD', 'JPY', 'EUR'];

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
      packPrice: defaultPackPrice,
      cigarettesPerPack: defaultCigarettesPerPack,
      currencyCode: defaultCurrencyCode,
      currencySymbol: defaultCurrencySymbol,
      darkModeEnabled: false,
    );
  }

  static AppMeta defaultMeta() {
    return const AppMeta(hasCompletedOnboarding: false, lastSmokingAt: null);
  }
}
