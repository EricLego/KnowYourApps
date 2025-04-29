import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_usage_model.dart';
import '../models/app_category_model.dart';
import '../models/mood_prediction_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'knowyourapps.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // App Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        isUserDefined INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // App Category Assignments table
    await db.execute('''
      CREATE TABLE category_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        isManualOverride INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // App Usage Records table
    await db.execute('''
      CREATE TABLE app_usage(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER NOT NULL,
        category TEXT NOT NULL,
        location TEXT,
        moodScore INTEGER,
        metadata TEXT
      )
    ''');

    // Mood Predictions table
    await db.execute('''
      CREATE TABLE mood_predictions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        score INTEGER NOT NULL,
        featureImportance TEXT NOT NULL,
        explanation TEXT,
        isUserProvided INTEGER NOT NULL
      )
    ''');

    // App Impact Scores table
    await db.execute('''
      CREATE TABLE app_impact_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        impactScore REAL NOT NULL,
        lastUpdated INTEGER NOT NULL,
        dataPointsCount INTEGER NOT NULL
      )
    ''');

    // Initialize with default categories
    await _initializeDefaultCategories(db);
  }

  Future<void> _initializeDefaultCategories(Database db) async {
    final defaultCategories = [
      {
        'name': 'Social Media',
        'description': 'Social networking and communication apps',
        'isUserDefined': 0,
        'colorValue': 0xFF4267B2, // Facebook blue
      },
      {
        'name': 'Productivity',
        'description': 'Work and productivity enhancement apps',
        'isUserDefined': 0,
        'colorValue': 0xFF4CAF50, // Green
      },
      {
        'name': 'Entertainment',
        'description': 'Video, music, and entertainment apps',
        'isUserDefined': 0,
        'colorValue': 0xFFFF5722, // Deep orange
      },
      {
        'name': 'Health & Fitness',
        'description': 'Health tracking and exercise apps',
        'isUserDefined': 0,
        'colorValue': 0xFF2196F3, // Blue
      },
      {
        'name': 'Education',
        'description': 'Learning and educational apps',
        'isUserDefined': 0,
        'colorValue': 0xFF9C27B0, // Purple
      },
      {
        'name': 'News & Reading',
        'description': 'News and reading apps',
        'isUserDefined': 0,
        'colorValue': 0xFFFFC107, // Amber
      },
      {
        'name': 'Games',
        'description': 'Mobile games and interactive entertainment',
        'isUserDefined': 0,
        'colorValue': 0xFFE91E63, // Pink
      },
      {
        'name': 'Utilities',
        'description': 'System and utility applications',
        'isUserDefined': 0,
        'colorValue': 0xFF607D8B, // Blue grey
      },
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // App Usage CRUD Operations
  Future<int> insertAppUsage(AppUsageRecord record) async {
    final db = await database;
    final data = record.toMap();
    
    // Convert metadata to JSON string
    if (data['metadata'] != null) {
      data['metadata'] = jsonEncode(data['metadata']);
    }
    
    return await db.insert('app_usage', data);
  }

  Future<List<AppUsageRecord>> getAppUsage({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'startTime >= ? AND endTime <= ?';
      whereArgs = [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch
      ];
    } else if (startDate != null) {
      whereClause = 'startTime >= ?';
      whereArgs = [startDate.millisecondsSinceEpoch];
    } else if (endDate != null) {
      whereClause = 'endTime <= ?';
      whereArgs = [endDate.millisecondsSinceEpoch];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'app_usage',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'startTime DESC',
    );

    return List.generate(maps.length, (i) {
      var map = maps[i];
      
      // Parse metadata JSON if it exists
      if (map['metadata'] != null) {
        map['metadata'] = jsonDecode(map['metadata']);
      }
      
      return AppUsageRecord.fromMap(map);
    });
  }

  // Categories CRUD Operations
  Future<int> insertCategory(AppCategory category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<AppCategory>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    
    return List.generate(maps.length, (i) {
      return AppCategory.fromMap(maps[i]);
    });
  }

  Future<int> updateCategory(AppCategory category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Category Assignments CRUD Operations
  Future<int> assignAppCategory(AppCategoryAssignment assignment) async {
    final db = await database;
    
    // Check if assignment already exists
    final existing = await db.query(
      'category_assignments',
      where: 'packageName = ?',
      whereArgs: [assignment.packageName],
    );
    
    if (existing.isNotEmpty) {
      // Update existing assignment
      return await db.update(
        'category_assignments',
        assignment.toMap(),
        where: 'packageName = ?',
        whereArgs: [assignment.packageName],
      );
    } else {
      // Create new assignment
      return await db.insert('category_assignments', assignment.toMap());
    }
  }

  Future<AppCategory?> getCategoryForApp(String packageName) async {
    final db = await database;
    
    // First check for manual assignment
    final assignmentList = await db.query(
      'category_assignments',
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
    
    if (assignmentList.isNotEmpty) {
      final assignment = AppCategoryAssignment.fromMap(assignmentList.first);
      final categoryList = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [assignment.categoryId],
      );
      
      if (categoryList.isNotEmpty) {
        return AppCategory.fromMap(categoryList.first);
      }
    }
    
    return null;
  }

  // Mood Prediction CRUD Operations
  Future<int> insertMoodPrediction(MoodPrediction prediction) async {
    final db = await database;
    final data = prediction.toMap();
    
    // Convert feature importance to JSON string
    data['featureImportance'] = jsonEncode(data['featureImportance']);
    
    return await db.insert('mood_predictions', data);
  }

  Future<List<MoodPrediction>> getMoodPredictions({
    DateTime? startDate,
    DateTime? endDate,
    bool userProvidedOnly = false,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userProvidedOnly) {
      whereClause = 'isUserProvided = 1';
    }
    
    if (startDate != null) {
      whereClause = whereClause.isNotEmpty ? '$whereClause AND ' : '';
      whereClause += 'timestamp >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause = whereClause.isNotEmpty ? '$whereClause AND ' : '';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_predictions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      var map = maps[i];
      
      // Parse feature importance JSON
      map['featureImportance'] = jsonDecode(map['featureImportance']);
      
      return MoodPrediction.fromMap(map);
    });
  }

  // App Impact Scores CRUD Operations
  Future<int> updateAppImpactScore(AppImpactScore impactScore) async {
    final db = await database;
    
    // Check if score already exists
    final existing = await db.query(
      'app_impact_scores',
      where: 'packageName = ?',
      whereArgs: [impactScore.packageName],
    );
    
    if (existing.isNotEmpty) {
      // Update existing score
      return await db.update(
        'app_impact_scores',
        impactScore.toMap(),
        where: 'packageName = ?',
        whereArgs: [impactScore.packageName],
      );
    } else {
      // Create new score
      return await db.insert('app_impact_scores', impactScore.toMap());
    }
  }

  Future<List<AppImpactScore>> getTopImpactingApps({
    int limit = 10,
    bool positive = true,
  }) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'app_impact_scores',
      where: positive ? 'impactScore > 0' : 'impactScore < 0',
      orderBy: positive ? 'impactScore DESC' : 'impactScore ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return AppImpactScore.fromMap(maps[i]);
    });
  }
}