class AppCategory {
  final int? id;
  final String name;
  final String description;
  final bool isUserDefined;
  final int colorValue;

  AppCategory({
    this.id,
    required this.name,
    required this.description,
    this.isUserDefined = false,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isUserDefined': isUserDefined ? 1 : 0,
      'colorValue': colorValue,
    };
  }

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      isUserDefined: map['isUserDefined'] == 1,
      colorValue: map['colorValue'],
    );
  }
}

class AppCategoryAssignment {
  final int? id;
  final String packageName;
  final int categoryId;
  final bool isManualOverride;

  AppCategoryAssignment({
    this.id,
    required this.packageName,
    required this.categoryId,
    this.isManualOverride = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'categoryId': categoryId,
      'isManualOverride': isManualOverride ? 1 : 0,
    };
  }

  factory AppCategoryAssignment.fromMap(Map<String, dynamic> map) {
    return AppCategoryAssignment(
      id: map['id'],
      packageName: map['packageName'],
      categoryId: map['categoryId'],
      isManualOverride: map['isManualOverride'] == 1,
    );
  }
}