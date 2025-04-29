import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/app_usage_model.dart';
import '../models/mood_prediction_model.dart';
import 'database_service.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  final DatabaseService _dbService = DatabaseService();
  
  // TFLite interpreter
  Interpreter? _interpreter;
  
  // App impact score cache
  final Map<String, double> _appImpactScores = {};
  
  // Whether the ML model is ready
  bool _isModelReady = false;
  
  // For periodic predictions
  Timer? _periodicPredictionTimer;

  factory MLService() => _instance;

  MLService._internal();

  Future<void> initialize() async {
    try {
      await _loadModel();
      _isModelReady = true;
      
      // Load app impact scores from database
      await _loadAppImpactScores();
      
      // Start periodic predictions (every 2 hours)
      _periodicPredictionTimer?.cancel();
      _periodicPredictionTimer = Timer.periodic(
        const Duration(hours: 2),
        (_) => generateMoodPrediction(),
      );
    } catch (e) {
      print('Error initializing ML service: $e');
      _isModelReady = false;
    }
  }

  Future<void> _loadModel() async {
    // This is a placeholder for loading a TFLite model
    // In a real app, we would have a pre-trained model file
    
    try {
      // In a real app, we would load the model file like this:
      // final modelFile = await _getModelFile();
      // _interpreter = await Interpreter.fromFile(modelFile);
      
      // For now, we'll simulate model loading
      await Future.delayed(const Duration(seconds: 1));
      // _interpreter = await Interpreter.fromAsset('assets/ml_models/mood_predictor.tflite');
      
      print('ML model loaded successfully');
    } catch (e) {
      print('Error loading ML model: $e');
      rethrow;
    }
  }

  Future<File> _getModelFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/mood_predictor.tflite';
    final modelFile = File(modelPath);
    
    if (!await modelFile.exists()) {
      // Copy from assets
      final modelData = await rootBundle.load('assets/ml_models/mood_predictor.tflite');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());
    }
    
    return modelFile;
  }

  Future<void> _loadAppImpactScores() async {
    try {
      // Load positive impact apps
      final positiveImpactApps = await _dbService.getTopImpactingApps(
        positive: true,
        limit: 50,
      );
      
      // Load negative impact apps
      final negativeImpactApps = await _dbService.getTopImpactingApps(
        positive: false,
        limit: 50,
      );
      
      // Combine all apps into the cache
      for (var app in [...positiveImpactApps, ...negativeImpactApps]) {
        _appImpactScores[app.packageName] = app.impactScore;
      }
    } catch (e) {
      print('Error loading app impact scores: $e');
    }
  }

  Future<MoodPrediction> generateMoodPrediction() async {
    if (!_isModelReady) {
      throw Exception('ML model is not ready');
    }
    
    try {
      // Get recent app usage (last 24 hours)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final recentUsage = await _dbService.getAppUsage(
        startDate: yesterday,
        endDate: now,
      );
      
      // This is where we would use the TFLite model to generate a prediction
      // For now, we'll simulate a prediction based on the app usage data
      
      final prediction = _simulatePrediction(recentUsage);
      
      // Store prediction in database
      await _dbService.insertMoodPrediction(prediction);
      
      // Update app impact scores
      await _updateAppImpactScores(recentUsage, prediction.score);
      
      return prediction;
    } catch (e) {
      print('Error generating mood prediction: $e');
      rethrow;
    }
  }

  MoodPrediction _simulatePrediction(List<AppUsageRecord> recentUsage) {
    // Group usage by app
    final appUsageTotals = <String, int>{};
    
    for (var record in recentUsage) {
      final duration = record.endTime.difference(record.startTime).inMinutes;
      appUsageTotals[record.packageName] = 
          (appUsageTotals[record.packageName] ?? 0) + duration;
    }
    
    // Calculate weighted score based on app impact scores
    double weightedScore = 0;
    final featureImportance = <String, double>{};
    
    // Add time of day feature (circadian rhythm simulation)
    final hour = DateTime.now().hour;
    double timeOfDayFactor = 0;
    
    // Early morning (5-8 AM): positive
    if (hour >= 5 && hour < 9) {
      timeOfDayFactor = 2.0;
    } 
    // Late night (11 PM - 4 AM): negative
    else if (hour >= 23 || hour < 5) {
      timeOfDayFactor = -2.0;
    }
    
    featureImportance['time_of_day'] = timeOfDayFactor * 0.3;
    weightedScore += featureImportance['time_of_day']!;
    
    // Add app usage features
    for (var entry in appUsageTotals.entries) {
      final packageName = entry.key;
      final usageMinutes = entry.value;
      
      // Get app impact score (default to slight negative for unknown apps)
      final impactScore = _appImpactScores[packageName] ?? -0.5;
      
      // Calculate this app's contribution (impact * usage with diminishing returns)
      final usageFactor = min(1.0, usageMinutes / 120); // Cap at 2 hours
      final appContribution = impactScore * usageFactor;
      
      // Record feature importance
      featureImportance[packageName] = appContribution;
      
      // Add to weighted score
      weightedScore += appContribution;
    }
    
    // Scale to -10 to 10 range and round to integer
    int finalScore = weightedScore.clamp(-10.0, 10.0).round();
    
    // Generate explanation based on top contributors
    final sortedFeatures = featureImportance.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    final topFeatures = sortedFeatures.take(3).toList();
    String explanation = '';
    
    if (finalScore > 3) {
      explanation = 'Your mood appears positive, likely influenced by ';
    } else if (finalScore < -3) {
      explanation = 'Your mood appears negative, possibly due to ';
    } else {
      explanation = 'Your mood appears neutral, with some influence from ';
    }
    
    for (int i = 0; i < topFeatures.length; i++) {
      final feature = topFeatures[i];
      if (feature.key == 'time_of_day') {
        if (feature.value > 0) {
          explanation += 'your healthy sleep schedule';
        } else if (feature.value < 0) {
          explanation += 'late night activity';
        }
      } else {
        // Get app name from package (simplified)
        final appName = feature.key.split('.').last;
        if (feature.value > 0) {
          explanation += 'positive time with $appName';
        } else if (feature.value < 0) {
          explanation += 'excessive time with $appName';
        }
      }
      
      if (i < topFeatures.length - 2) {
        explanation += ', ';
      } else if (i == topFeatures.length - 2) {
        explanation += ' and ';
      }
    }
    
    explanation += '.';
    
    return MoodPrediction(
      timestamp: DateTime.now(),
      score: finalScore,
      featureImportance: featureImportance,
      explanation: explanation,
      isUserProvided: false,
    );
  }

  Future<void> _updateAppImpactScores(List<AppUsageRecord> recentUsage, int moodScore) async {
    // Group usage by app
    final appUsageTotals = <String, int>{};
    final appNames = <String, String>{};
    
    for (var record in recentUsage) {
      final duration = record.endTime.difference(record.startTime).inMinutes;
      appUsageTotals[record.packageName] = 
          (appUsageTotals[record.packageName] ?? 0) + duration;
      appNames[record.packageName] = record.appName;
    }
    
    // Update impact scores for apps with significant usage
    for (var entry in appUsageTotals.entries) {
      final packageName = entry.key;
      final usageMinutes = entry.value;
      
      // Only consider apps with at least 15 minutes of usage
      if (usageMinutes < 15) continue;
      
      // Get current impact score
      double currentScore = _appImpactScores[packageName] ?? 0.0;
      int dataPoints = 1;
      
      // Calculate new impact score with exponential moving average
      // New apps have higher learning rate
      double learningRate = currentScore == 0.0 ? 0.5 : 0.1;
      
      // Scale mood score to -1.0 to 1.0 range
      double scaledMoodScore = moodScore / 10.0;
      
      // Apply usage-weighted contribution to the score
      double usageWeight = min(1.0, usageMinutes / 120); // Cap at 2 hours
      double contribution = scaledMoodScore * usageWeight;
      
      // Update score with moving average
      double newScore = currentScore * (1 - learningRate) + contribution * learningRate;
      
      // Cap at -5.0 to 5.0 range
      newScore = newScore.clamp(-5.0, 5.0);
      
      // Update local cache
      _appImpactScores[packageName] = newScore;
      
      // Update database
      await _dbService.updateAppImpactScore(
        AppImpactScore(
          packageName: packageName,
          appName: appNames[packageName] ?? packageName,
          impactScore: newScore,
          lastUpdated: DateTime.now(),
          dataPointsCount: dataPoints,
        ),
      );
    }
  }

  Future<void> addUserMoodFeedback(int moodScore, {String? explanation}) async {
    // Create user-provided mood prediction
    final userMood = MoodPrediction(
      timestamp: DateTime.now(),
      score: moodScore.clamp(-10, 10),
      featureImportance: {},  // Empty for user-provided moods
      explanation: explanation,
      isUserProvided: true,
    );
    
    // Store in database
    await _dbService.insertMoodPrediction(userMood);
    
    // Fetch recent app usage (last 3 hours)
    final now = DateTime.now();
    final threeHoursAgo = now.subtract(const Duration(hours: 3));
    final recentUsage = await _dbService.getAppUsage(
      startDate: threeHoursAgo,
      endDate: now,
    );
    
    // Update app impact scores with higher learning rate
    await _updateAppImpactScores(recentUsage, moodScore);
  }

  void dispose() {
    _periodicPredictionTimer?.cancel();
    _interpreter?.close();
  }
}