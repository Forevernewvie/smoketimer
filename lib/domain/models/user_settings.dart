enum RingReference { lastSmoking, dayStart }

class UserSettings {
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
    );
  }

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
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final weekdayList =
        (json['activeWeekdays'] as List<dynamic>? ?? <dynamic>[])
            .map((value) => (value as num).toInt())
            .toSet();

    return UserSettings(
      intervalMinutes: (json['intervalMinutes'] as num).toInt(),
      preAlertMinutes: (json['preAlertMinutes'] as num).toInt(),
      repeatEnabled: json['repeatEnabled'] as bool,
      allowedStartMinutes: (json['allowedStartMinutes'] as num).toInt(),
      allowedEndMinutes: (json['allowedEndMinutes'] as num).toInt(),
      activeWeekdays: weekdayList,
      use24Hour: json['use24Hour'] as bool,
      ringReference: RingReference.values.firstWhere(
        (item) => item.name == json['ringReference'],
        orElse: () => RingReference.lastSmoking,
      ),
      vibrationEnabled: json['vibrationEnabled'] as bool,
      soundType: json['soundType'] as String,
    );
  }

  String get ringReferenceLabel {
    switch (ringReference) {
      case RingReference.lastSmoking:
        return '마지막 흡연';
      case RingReference.dayStart:
        return '오늘 시작';
    }
  }

  String get soundTypeLabel {
    switch (soundType) {
      case 'silent':
        return '무음';
      case 'default':
      default:
        return '기본';
    }
  }
}
