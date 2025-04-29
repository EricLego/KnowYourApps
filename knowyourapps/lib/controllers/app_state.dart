import 'package:flutter/material.dart';
import '../models/app_usage_model.dart';
import '../models/app_category_model.dart';
import '../models/mood_prediction_model.dart';
import '../services/database_service.dart';
import '../services/usage_service.dart';
import '../services/category_service.dart';
import '../services/ml_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final UsageService _usageService = UsageService();
  final CategoryService _categoryService = CategoryService();
  final MLService _mlService = MLService();
  
  // Current user mood score
  int _currentMoodScore = 0;
  
  // App usage data
  List<AppUsageRecord> _recentUsage = [];
  List<AppUsageRecord> _dailyUsage = [];
  List<AppUsageRecord> _weeklyUsage = [];
  
  // Categories
  List<AppCategory> _categories = [];
  
  // Mood predictions
  List<MoodPrediction> _recentMoodPredictions = [];
  MoodPrediction? _latestMoodPrediction;
  
  // App impact scores
  List<AppImpactScore> _topPositiveApps = [];
  List<AppImpactScore> _topNegativeApps = [];
  
  // Loading states
  bool _isLoadingUsage = false;
  bool _isLoadingCategories = false;
  bool _isLoadingMoodPredictions = false;
  bool _isLoadingImpactScores = false;
  
  // Getters
  int get currentMoodScore => _currentMoodScore;
  List<AppUsageRecord> get recentUsage => _recentUsage;
  List<AppUsageRecord> get dailyUsage => _dailyUsage;
  List<AppUsageRecord> get weeklyUsage => _weeklyUsage;
  List<AppCategory> get categories => _categories;
  List<MoodPrediction> get recentMoodPredictions => _recentMoodPredictions;
  MoodPrediction? get latestMoodPrediction => _latestMoodPrediction;
  List<AppImpactScore> get topPositiveApps => _topPositiveApps;
  List<AppImpactScore> get topNegativeApps => _topNegativeApps;
  
  // Loading states getters
  bool get isLoadingUsage => _isLoadingUsage;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingMoodPredictions => _isLoadingMoodPredictions;
  bool get isLoadingImpactScores => _isLoadingImpactScores;
  
  AppState() {
    // Initialize data
    loadInitialData();
  }
  
  Future<void> loadInitialData() async {
    await loadCategories();
    await loadRecentUsage();
    await loadDailyUsage();
    await loadWeeklyUsage();
    await loadMoodPredictions();
    await loadAppImpactScores();
  }
  
  // App Usage Methods
  Future<void> loadRecentUsage() async {
    _isLoadingUsage = true;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      
      _recentUsage = await _dbService.getAppUsage(
        startDate: threeDaysAgo,
        endDate: now,
      );
      
      _isLoadingUsage = false;
      notifyListeners();
    } catch (e) {
      print('Error loading recent usage: $e');
      _isLoadingUsage = false;
      notifyListeners();
    }
  }
  
  Future<void> loadDailyUsage() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      _dailyUsage = await _dbService.getAppUsage(
        startDate: startOfDay,
        endDate: now,
      );
      
      notifyListeners();
    } catch (e) {
      print('Error loading daily usage: $e');
    }
  }
  
  Future<void> loadWeeklyUsage() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      _weeklyUsage = await _dbService.getAppUsage(
        startDate: startDate,
        endDate: now,
      );
      
      notifyListeners();
    } catch (e) {
      print('Error loading weekly usage: $e');
    }
  }
  
  Future<void> refreshUsageData() async {
    await _usageService.fetchAndStoreUsageData();
    await loadRecentUsage();
    await loadDailyUsage();
    await loadWeeklyUsage();
  }
  
  // Category Methods
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();
    
    try {
      _categories = await _categoryService.getAllCategories();
      
      _isLoadingCategories = false;
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
      _isLoadingCategories = false;
      notifyListeners();
    }
  }
  
  Future<void> createCategory(String name, String description, Color color) async {
    try {
      await _categoryService.createCategory(name, description, color);
      await loadCategories();
    } catch (e) {
      print('Error creating category: $e');
    }
  }
  
  Future<void> updateCategory(AppCategory category) async {
    try {
      await _categoryService.updateCategory(category);
      await loadCategories();
    } catch (e) {
      print('Error updating category: $e');
    }
  }
  
  Future<void> assignAppToCategory(String packageName, int categoryId) async {
    try {
      await _categoryService.assignAppToCategory(
        packageName,
        categoryId,
        isManualOverride: true,
      );
      
      // Refresh usage data to show updated categories
      await loadRecentUsage();
    } catch (e) {
      print('Error assigning app to category: $e');
    }
  }
  
  // Mood Prediction Methods
  Future<void> loadMoodPredictions() async {
    _isLoadingMoodPredictions = true;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      _recentMoodPredictions = await _dbService.getMoodPredictions(
        startDate: sevenDaysAgo,
        endDate: now,
      );
      
      if (_recentMoodPredictions.isNotEmpty) {
        _latestMoodPrediction = _recentMoodPredictions.first;
        _currentMoodScore = _latestMoodPrediction!.score;
      }
      
      _isLoadingMoodPredictions = false;
      notifyListeners();
    } catch (e) {
      print('Error loading mood predictions: $e');
      _isLoadingMoodPredictions = false;
      notifyListeners();
    }
  }
  
  Future<void> generateMoodPrediction() async {
    try {
      final prediction = await _mlService.generateMoodPrediction();
      _latestMoodPrediction = prediction;
      _currentMoodScore = prediction.score;
      
      // Reload mood predictions
      await loadMoodPredictions();
      
      // Reload app impact scores
      await loadAppImpactScores();
    } catch (e) {
      print('Error generating mood prediction: $e');
    }
  }
  
  Future<void> provideMoodFeedback(int moodScore, {String? explanation}) async {
    try {
      await _mlService.addUserMoodFeedback(moodScore, explanation: explanation);
      _currentMoodScore = moodScore;
      
      // Reload mood predictions
      await loadMoodPredictions();
      
      // Reload app impact scores
      await loadAppImpactScores();
      
      notifyListeners();
    } catch (e) {
      print('Error providing mood feedback: $e');
    }
  }
  
  // App Impact Score Methods
  Future<void> loadAppImpactScores() async {
    _isLoadingImpactScores = true;
    notifyListeners();
    
    try {
      _topPositiveApps = await _dbService.getTopImpactingApps(
        positive: true,
        limit: 5,
      );
      
      _topNegativeApps = await _dbService.getTopImpactingApps(
        positive: false,
        limit: 5,
      );
      
      _isLoadingImpactScores = false;
      notifyListeners();
    } catch (e) {
      print('Error loading app impact scores: $e');
      _isLoadingImpactScores = false;
      notifyListeners();
    }
  }
}