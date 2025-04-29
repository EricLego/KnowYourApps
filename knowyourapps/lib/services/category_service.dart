import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_category_model.dart';
import 'database_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  final DatabaseService _dbService = DatabaseService();
  
  // In-memory cache of categories
  List<AppCategory> _categories = [];
  
  // Cache of app-to-category assignments
  final Map<String, int> _appCategoryAssignments = {};

  factory CategoryService() => _instance;

  CategoryService._internal();

  Future<void> initialize() async {
    await loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _dbService.getAllCategories();
  }

  Future<List<AppCategory>> getAllCategories() async {
    if (_categories.isEmpty) {
      await loadCategories();
    }
    return _categories;
  }

  Future<AppCategory?> getCategoryForApp(String packageName) async {
    // Check cache first
    final categoryId = _appCategoryAssignments[packageName];
    if (categoryId != null) {
      return _categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => null,
      );
    }
    
    // Check database
    final category = await _dbService.getCategoryForApp(packageName);
    if (category != null) {
      _appCategoryAssignments[packageName] = category.id!;
      return category;
    }
    
    // Auto-categorize based on package name
    final autoCategory = _autoCategorize(packageName);
    if (autoCategory != null) {
      await assignAppToCategory(packageName, autoCategory.id!, isManualOverride: false);
      return autoCategory;
    }
    
    // Default to "Unknown" category
    return _getOrCreateUnknownCategory();
  }

  Future<int> assignAppToCategory(String packageName, int categoryId, {bool isManualOverride = true}) async {
    final assignment = AppCategoryAssignment(
      packageName: packageName,
      categoryId: categoryId,
      isManualOverride: isManualOverride,
    );
    
    // Update cache
    _appCategoryAssignments[packageName] = categoryId;
    
    // Update database
    return await _dbService.assignAppCategory(assignment);
  }

  Future<AppCategory> createCategory(String name, String description, Color color) async {
    final category = AppCategory(
      name: name,
      description: description,
      isUserDefined: true,
      colorValue: color.value,
    );
    
    final id = await _dbService.insertCategory(category);
    final newCategory = AppCategory(
      id: id,
      name: name,
      description: description,
      isUserDefined: true,
      colorValue: color.value,
    );
    
    // Update in-memory cache
    _categories.add(newCategory);
    
    return newCategory;
  }

  Future<int> updateCategory(AppCategory category) async {
    final result = await _dbService.updateCategory(category);
    
    // Update in-memory cache
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
    
    return result;
  }

  // Auto-categorizes apps based on package name keywords
  AppCategory? _autoCategorize(String packageName) {
    final packageNameLower = packageName.toLowerCase();
    
    // Social Media
    if (_containsAnyKeyword(packageNameLower, ['facebook', 'instagram', 'twitter', 'tiktok', 'snapchat', 'whatsapp', 'telegram', 'messenger', 'social', 'chat'])) {
      return _findCategoryByName('Social Media');
    }
    
    // Productivity
    if (_containsAnyKeyword(packageNameLower, ['office', 'docs', 'sheets', 'slides', 'word', 'excel', 'powerpoint', 'calendar', 'email', 'mail', 'task', 'todo', 'note', 'work', 'productivity'])) {
      return _findCategoryByName('Productivity');
    }
    
    // Entertainment
    if (_containsAnyKeyword(packageNameLower, ['netflix', 'youtube', 'spotify', 'music', 'video', 'player', 'movie', 'stream', 'entertainment', 'media', 'tv'])) {
      return _findCategoryByName('Entertainment');
    }
    
    // Health & Fitness
    if (_containsAnyKeyword(packageNameLower, ['fitness', 'health', 'workout', 'exercise', 'run', 'step', 'track', 'diet', 'meditation', 'yoga'])) {
      return _findCategoryByName('Health & Fitness');
    }
    
    // Education
    if (_containsAnyKeyword(packageNameLower, ['learn', 'edu', 'course', 'study', 'school', 'college', 'university', 'quiz', 'knowledge', 'educational'])) {
      return _findCategoryByName('Education');
    }
    
    // News & Reading
    if (_containsAnyKeyword(packageNameLower, ['news', 'read', 'book', 'magazine', 'article', 'paper', 'blog', 'rss', 'feed'])) {
      return _findCategoryByName('News & Reading');
    }
    
    // Games
    if (_containsAnyKeyword(packageNameLower, ['game', 'play', 'puzzle', 'arcade', 'fun', 'gaming'])) {
      return _findCategoryByName('Games');
    }
    
    // Utilities
    if (_containsAnyKeyword(packageNameLower, ['util', 'tool', 'file', 'manager', 'browser', 'calculator', 'clock', 'backup', 'security', 'system'])) {
      return _findCategoryByName('Utilities');
    }
    
    return null;
  }

  bool _containsAnyKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  AppCategory? _findCategoryByName(String name) {
    try {
      return _categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  Future<AppCategory> _getOrCreateUnknownCategory() async {
    // Try to find existing Unknown category
    final unknownCategory = _findCategoryByName('Unknown');
    if (unknownCategory != null) {
      return unknownCategory;
    }
    
    // Create Unknown category if it doesn't exist
    return await createCategory(
      'Unknown',
      'Uncategorized applications',
      Colors.grey,
    );
  }
}