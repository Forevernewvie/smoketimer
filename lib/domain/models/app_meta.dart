class AppMeta {
  const AppMeta({required this.hasCompletedOnboarding, this.lastSmokingAt});

  final bool hasCompletedOnboarding;
  final DateTime? lastSmokingAt;

  AppMeta copyWith({
    bool? hasCompletedOnboarding,
    DateTime? lastSmokingAt,
    bool clearLastSmokingAt = false,
  }) {
    return AppMeta(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastSmokingAt: clearLastSmokingAt
          ? null
          : (lastSmokingAt ?? this.lastSmokingAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'lastSmokingAt': lastSmokingAt?.toIso8601String(),
    };
  }

  factory AppMeta.fromJson(Map<String, dynamic> json) {
    return AppMeta(
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool,
      lastSmokingAt: json['lastSmokingAt'] == null
          ? null
          : DateTime.parse(json['lastSmokingAt'] as String),
    );
  }
}
