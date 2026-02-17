class SmokingRecord {
  const SmokingRecord({
    required this.id,
    required this.timestamp,
    this.count = 1,
  });

  final String id;
  final DateTime timestamp;
  final int count;

  SmokingRecord copyWith({String? id, DateTime? timestamp, int? count}) {
    return SmokingRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'timestamp': timestamp.toIso8601String(), 'count': count};
  }

  factory SmokingRecord.fromJson(Map<String, dynamic> json) {
    return SmokingRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }
}
