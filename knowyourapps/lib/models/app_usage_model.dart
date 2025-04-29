class AppUsageRecord {
  final int? id;
  final String packageName;
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String? location;
  final int? moodScore;
  final Map<String, dynamic>? metadata;

  AppUsageRecord({
    this.id,
    required this.packageName,
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.location,
    this.moodScore,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'category': category,
      'location': location,
      'moodScore': moodScore,
      'metadata': metadata != null ? Map<String, dynamic>.from(metadata!) : null,
    };
  }

  factory AppUsageRecord.fromMap(Map<String, dynamic> map) {
    return AppUsageRecord(
      id: map['id'],
      packageName: map['packageName'],
      appName: map['appName'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      category: map['category'],
      location: map['location'],
      moodScore: map['moodScore'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  AppUsageRecord copyWith({
    int? id,
    String? packageName,
    String? appName,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? location,
    int? moodScore,
    Map<String, dynamic>? metadata,
  }) {
    return AppUsageRecord(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      location: location ?? this.location,
      moodScore: moodScore ?? this.moodScore,
      metadata: metadata ?? this.metadata,
    );
  }
}