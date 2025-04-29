import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_state.dart';
import '../../models/app_category_model.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddCategoryDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final categories = appState.categories;
          
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories available.'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, AppCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          _showCategoryAppsDialog(context, category);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(category.colorValue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    category.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (category.isUserDefined)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditCategoryDialog(context, category);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    Color selectedColor = Colors.blue;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'Enter category name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter category description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildColorOption(Colors.blue, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.green, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.red, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.orange, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.purple, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.teal, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    await appState.createCategory(
                      _nameController.text,
                      _descriptionController.text,
                      selectedColor,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, AppCategory category) {
    final TextEditingController _nameController = TextEditingController(text: category.name);
    final TextEditingController _descriptionController = TextEditingController(text: category.description);
    Color selectedColor = Color(category.colorValue);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildColorOption(Colors.blue, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.green, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.red, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.orange, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.purple, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                    _buildColorOption(Colors.teal, selectedColor, (color) {
                      setState(() => selectedColor = color);
                    }),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    final updatedCategory = AppCategory(
                      id: category.id,
                      name: _nameController.text,
                      description: _descriptionController.text,
                      isUserDefined: category.isUserDefined,
                      colorValue: selectedColor.value,
                    );
                    await appState.updateCategory(updatedCategory);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCategoryAppsDialog(BuildContext context, AppCategory category) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        // Filter apps by category
        final categoryApps = appState.recentUsage.where(
          (app) => app.category == category.name
        ).toList();
        
        // Get unique apps
        final uniqueApps = <String, String>{};
        for (var app in categoryApps) {
          uniqueApps[app.packageName] = app.appName;
        }
        
        return AlertDialog(
          title: Text('Apps in ${category.name}'),
          content: Container(
            width: double.maxFinite,
            child: uniqueApps.isEmpty
                ? const Text('No apps in this category.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueApps.length,
                    itemBuilder: (context, index) {
                      final packageName = uniqueApps.keys.elementAt(index);
                      final appName = uniqueApps.values.elementAt(index);
                      
                      return ListTile(
                        title: Text(appName),
                        subtitle: Text(packageName),
                        trailing: IconButton(
                          icon: const Icon(Icons.category),
                          onPressed: () {
                            Navigator.pop(context);
                            _showChangeCategoryDialog(context, packageName, appName);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeCategoryDialog(BuildContext context, String packageName, String appName) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Category for $appName'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: appState.categories.length,
              itemBuilder: (context, index) {
                final category = appState.categories[index];
                
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(category.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(category.name),
                  onTap: () async {
                    await appState.assignAppToCategory(packageName, category.id!);
                    Navigator.pop(context);
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$appName assigned to ${category.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorOption(Color color, Color selectedColor, ValueChanged<Color> onColorSelected) {
    final isSelected = color.value == selectedColor.value;
    
    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
      ),
    );
  }
}