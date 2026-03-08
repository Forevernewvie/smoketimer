import '../../domain/app_defaults.dart';
import '../../domain/models/user_settings.dart';
import '../../services/cost_stats_service.dart';

/// Pure policy object that centralizes all user-settings mutations.
class AppSettingsPolicy {
  /// Prevents accidental instantiation of this pure utility class.
  const AppSettingsPolicy._();

  /// Returns settings with repeat alerts toggled.
  static UserSettings toggleRepeatEnabled(UserSettings current) {
    return current.copyWith(repeatEnabled: !current.repeatEnabled);
  }

  /// Returns settings with the next configured interval option selected.
  static UserSettings cycleIntervalMinutes(UserSettings current) {
    final index = AppDefaults.intervalOptions.indexOf(current.intervalMinutes);
    final next = AppDefaults
        .intervalOptions[(index + 1) % AppDefaults.intervalOptions.length];
    return current.copyWith(intervalMinutes: next);
  }

  /// Returns normalized interval settings or null when no effective change exists.
  static UserSettings? setIntervalMinutes(UserSettings current, int minutes) {
    final normalized = minutes
        .clamp(AppDefaults.minIntervalMinutes, AppDefaults.maxIntervalMinutes)
        .toInt();
    if (normalized == current.intervalMinutes) {
      return null;
    }
    return current.copyWith(intervalMinutes: normalized);
  }

  /// Returns settings with the next configured pre-alert option selected.
  static UserSettings cyclePreAlertMinutes(UserSettings current) {
    final index = AppDefaults.preAlertOptions.indexOf(current.preAlertMinutes);
    final next = AppDefaults
        .preAlertOptions[(index + 1) % AppDefaults.preAlertOptions.length];
    return current.copyWith(preAlertMinutes: next);
  }

  /// Returns normalized pre-alert settings or null when no effective change exists.
  static UserSettings? setPreAlertMinutes(UserSettings current, int minutes) {
    final normalized = minutes
        .clamp(AppDefaults.minPreAlertMinutes, AppDefaults.maxPreAlertMinutes)
        .toInt();
    if (normalized == current.preAlertMinutes) {
      return null;
    }
    return current.copyWith(preAlertMinutes: normalized);
  }

  /// Returns validated scheduling-window settings or null when invalid/unchanged.
  static UserSettings? updateAllowedTimeWindow(
    UserSettings current, {
    required int startMinutes,
    required int endMinutes,
  }) {
    final isInvalid =
        startMinutes < AppDefaults.allowedWindowMinMinutes ||
        endMinutes > AppDefaults.allowedWindowMaxMinutes ||
        endMinutes <= startMinutes;
    if (isInvalid) {
      return null;
    }
    if (startMinutes == current.allowedStartMinutes &&
        endMinutes == current.allowedEndMinutes) {
      return null;
    }
    return current.copyWith(
      allowedStartMinutes: startMinutes,
      allowedEndMinutes: endMinutes,
    );
  }

  /// Returns settings with the provided weekday toggled in the active set.
  static UserSettings toggleWeekday(UserSettings current, int weekday) {
    final updatedWeekdays = {...current.activeWeekdays};
    if (updatedWeekdays.contains(weekday)) {
      updatedWeekdays.remove(weekday);
    } else {
      updatedWeekdays.add(weekday);
    }
    return current.copyWith(activeWeekdays: updatedWeekdays);
  }

  /// Returns settings with 24-hour display toggled.
  static UserSettings toggleUse24Hour(UserSettings current) {
    return current.copyWith(use24Hour: !current.use24Hour);
  }

  /// Returns settings with the next ring reference selected.
  static UserSettings cycleRingReference(UserSettings current) {
    return current.copyWith(
      ringReference: current.ringReference == RingReference.lastSmoking
          ? RingReference.dayStart
          : RingReference.lastSmoking,
    );
  }

  /// Returns settings with vibration toggled.
  static UserSettings toggleVibration(UserSettings current) {
    return current.copyWith(vibrationEnabled: !current.vibrationEnabled);
  }

  /// Returns settings with the next available sound type selected.
  static UserSettings cycleSoundType(UserSettings current) {
    final index = AppDefaults.soundTypeOptions.indexOf(current.soundType);
    final next = AppDefaults
        .soundTypeOptions[(index + 1) % AppDefaults.soundTypeOptions.length];
    return current.copyWith(soundType: next);
  }

  /// Returns settings with explicit dark mode toggled.
  static UserSettings toggleDarkMode(UserSettings current) {
    return current.copyWith(darkModeEnabled: !current.darkModeEnabled);
  }

  /// Returns normalized pack-price settings or null when no effective change exists.
  static UserSettings? setPackPrice(UserSettings current, double packPrice) {
    final normalized = CostStatsService.normalizePackPrice(packPrice);
    if (normalized == current.packPrice) {
      return null;
    }
    return current.copyWith(packPrice: normalized);
  }

  /// Returns normalized cigarettes-per-pack settings or null when unchanged.
  static UserSettings? setCigarettesPerPack(
    UserSettings current,
    int cigarettesPerPack,
  ) {
    final normalized = CostStatsService.normalizeCigarettesPerPack(
      cigarettesPerPack,
    );
    if (normalized == current.cigarettesPerPack) {
      return null;
    }
    return current.copyWith(cigarettesPerPack: normalized);
  }

  /// Returns normalized currency settings or null when no effective change exists.
  static UserSettings? setCurrencyCode(
    UserSettings current,
    String currencyCode,
  ) {
    final normalized = currencyCode.trim().toUpperCase();
    final nextCode = normalized.isEmpty
        ? AppDefaults.defaultCurrencyCode
        : normalized;
    final nextSymbol = CostStatsService.resolveCurrencySymbol(nextCode);

    if (nextCode == current.currencyCode &&
        nextSymbol == current.currencySymbol) {
      return null;
    }
    return current.copyWith(currencyCode: nextCode, currencySymbol: nextSymbol);
  }
}
