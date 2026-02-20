import '../app_defaults.dart';

enum RingReference { lastSmoking, dayStart }

class UserSettings {
  /// Creates immutable user settings object.
  const UserSettings({
    required this.intervalMinutes,
    required this.preAlertMinutes,
    required this.repeatEnabled,
    required this.allowedStartMinutes,
    required this.allowedEndMinutes,
    required this.activeWeekdays,
    required this.use24Hour,
    required this.ringReference,
    required this.vibrationEnabled,
    required this.soundType,
    required this.packPrice,
    required this.cigarettesPerPack,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final int intervalMinutes;
  final int preAlertMinutes;
  final bool repeatEnabled;
  final int allowedStartMinutes;
  final int allowedEndMinutes;
  final Set<int> activeWeekdays;
  final bool use24Hour;
  final RingReference ringReference;
  final bool vibrationEnabled;
  final String soundType;
  final double packPrice;
  final int cigarettesPerPack;
  final String currencyCode;
  final String currencySymbol;

  /// Returns a copied settings object with selected overrides.
  UserSettings copyWith({
    int? intervalMinutes,
    int? preAlertMinutes,
    bool? repeatEnabled,
    int? allowedStartMinutes,
    int? allowedEndMinutes,
    Set<int>? activeWeekdays,
    bool? use24Hour,
    RingReference? ringReference,
    bool? vibrationEnabled,
    String? soundType,
    double? packPrice,
    int? cigarettesPerPack,
    String? currencyCode,
    String? currencySymbol,
    bool clearCurrencySymbol = false,
  }) {
    return UserSettings(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      preAlertMinutes: preAlertMinutes ?? this.preAlertMinutes,
      repeatEnabled: repeatEnabled ?? this.repeatEnabled,
      allowedStartMinutes: allowedStartMinutes ?? this.allowedStartMinutes,
      allowedEndMinutes: allowedEndMinutes ?? this.allowedEndMinutes,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      use24Hour: use24Hour ?? this.use24Hour,
      ringReference: ringReference ?? this.ringReference,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundType: soundType ?? this.soundType,
      packPrice: packPrice ?? this.packPrice,
      cigarettesPerPack: cigarettesPerPack ?? this.cigarettesPerPack,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: clearCurrencySymbol
          ? ''
          : (currencySymbol ?? this.currencySymbol),
    );
  }

  /// Serializes settings into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'intervalMinutes': intervalMinutes,
      'preAlertMinutes': preAlertMinutes,
      'repeatEnabled': repeatEnabled,
      'allowedStartMinutes': allowedStartMinutes,
      'allowedEndMinutes': allowedEndMinutes,
      'activeWeekdays': activeWeekdays.toList()..sort(),
      'use24Hour': use24Hour,
      'ringReference': ringReference.name,
      'vibrationEnabled': vibrationEnabled,
      'soundType': soundType,
      'packPrice': packPrice,
      'cigarettesPerPack': cigarettesPerPack,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }

  /// Deserializes settings with backward-compatible default fallback.
  factory UserSettings.fromJson(
    Map<String, dynamic> json, {
    UserSettings? defaults,
  }) {
    final parsedWeekdayList =
        (json['activeWeekdays'] as List<dynamic>? ?? <dynamic>[])
            .map((value) => (value as num).toInt())
            .toSet();
    final weekdayList = parsedWeekdayList.isEmpty
        ? (defaults?.activeWeekdays ?? <int>{1, 2, 3, 4, 5})
        : parsedWeekdayList;

    return UserSettings(
      intervalMinutes:
          (json['intervalMinutes'] as num?)?.toInt() ??
          defaults?.intervalMinutes ??
          AppDefaults.intervalMinutes,
      preAlertMinutes:
          (json['preAlertMinutes'] as num?)?.toInt() ??
          defaults?.preAlertMinutes ??
          AppDefaults.preAlertMinutes,
      repeatEnabled:
          (json['repeatEnabled'] as bool?) ?? defaults?.repeatEnabled ?? true,
      allowedStartMinutes:
          (json['allowedStartMinutes'] as num?)?.toInt() ??
          defaults?.allowedStartMinutes ??
          AppDefaults.allowedStartMinutes,
      allowedEndMinutes:
          (json['allowedEndMinutes'] as num?)?.toInt() ??
          defaults?.allowedEndMinutes ??
          AppDefaults.allowedEndMinutes,
      activeWeekdays: weekdayList,
      use24Hour: (json['use24Hour'] as bool?) ?? defaults?.use24Hour ?? true,
      ringReference: RingReference.values.firstWhere(
        (item) => item.name == json['ringReference'],
        orElse: () => defaults?.ringReference ?? RingReference.lastSmoking,
      ),
      vibrationEnabled:
          (json['vibrationEnabled'] as bool?) ??
          defaults?.vibrationEnabled ??
          true,
      soundType:
          (json['soundType'] as String?) ?? defaults?.soundType ?? 'default',
      packPrice:
          (json['packPrice'] as num?)?.toDouble() ??
          defaults?.packPrice ??
          AppDefaults.defaultPackPrice,
      cigarettesPerPack:
          (json['cigarettesPerPack'] as num?)?.toInt() ??
          defaults?.cigarettesPerPack ??
          AppDefaults.defaultCigarettesPerPack,
      currencyCode:
          (json['currencyCode'] as String?) ??
          defaults?.currencyCode ??
          AppDefaults.defaultCurrencyCode,
      currencySymbol:
          (json['currencySymbol'] as String?) ??
          defaults?.currencySymbol ??
          AppDefaults.defaultCurrencySymbol,
    );
  }

  /// Human-friendly label for ring reference mode.
  String get ringReferenceLabel {
    switch (ringReference) {
      case RingReference.lastSmoking:
        return '마지막 흡연';
      case RingReference.dayStart:
        return '오늘 시작';
    }
  }

  /// Human-friendly label for sound mode.
  String get soundTypeLabel {
    switch (soundType) {
      case 'silent':
        return '무음';
      case 'default':
      default:
        return '기본';
    }
  }

  /// Indicates whether cost tracking can be computed safely.
  bool get isCostTrackingEnabled => packPrice > 0 && cigarettesPerPack > 0;

  /// Returns currency label used by settings UI.
  String get currencyLabel {
    if (currencySymbol.isEmpty) {
      return currencyCode;
    }
    return '$currencyCode ($currencySymbol)';
  }
}
