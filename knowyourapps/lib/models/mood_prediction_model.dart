class MoodPrediction {
  final int? id;
  final DateTime timestamp;
  final int score; // -10 to +10 scale
  final Map<String, double> featureImportance;
  final String? explanation;
  final bool isUserProvided;

  MoodPrediction({
    this.id,
    required this.timestamp,
    required this.score,
    required this.featureImportance,
    this.explanation,
    this.isUserProvided = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'score': score,
      'featureImportance': featureImportance,
      'explanation': explanation,
      'isUserProvided': isUserProvided ? 1 : 0,
    };
  }

  factory MoodPrediction.fromMap(Map<String, dynamic> map) {
    return MoodPrediction(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      score: map['score'],
      featureImportance: Map<String, double>.from(map['featureImportance']),
      explanation: map['explanation'],
      isUserProvided: map['isUserProvided'] == 1,
    );
  }
}

class AppImpactScore {
  final int? id;
  final String packageName;
  final String appName;
  final double impactScore; // -10 to +10 scale
  final DateTime lastUpdated;
  final int dataPointsCount;

  AppImpactScore({
    this.id,
    required this.packageName,
    required this.appName,
    required this.impactScore,
    required this.lastUpdated,
    this.dataPointsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'impactScore': impactScore,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'dataPointsCount': dataPointsCount,
    };
  }

  factory AppImpactScore.fromMap(Map<String, dynamic> map) {
    return AppImpactScore(
      id: map['id'],
      packageName: map['packageName'],
      appName: map['appName'],
      impactScore: map['impactScore'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
      dataPointsCount: map['dataPointsCount'],
    );
  }
}