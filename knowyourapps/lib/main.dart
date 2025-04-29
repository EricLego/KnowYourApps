import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/app_state.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/insights_screen.dart';
import 'views/screens/categories_screen.dart';
import 'views/screens/settings_screen.dart';
import 'services/database_service.dart';
import 'services/usage_service.dart';
import 'services/category_service.dart';
import 'services/ml_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await DatabaseService()._initDatabase();
  await CategoryService().initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Know Your Apps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const InsightsScreen(),
    const CategoriesScreen(),
    const SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final usageService = UsageService();
    final mlService = MLService();
    
    // Request permissions
    final hasPermission = await usageService.requestPermissions();
    
    if (hasPermission) {
      // Start tracking app usage
      await usageService.startTracking();
      
      // Initialize ML service
      await mlService.initialize();
    } else {
      // Show permission request dialog
      _showPermissionDialog();
    }
  }
  
  void _showPermissionDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs permission to access usage statistics to track your app usage patterns. '
            'Please grant this permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final usageService = UsageService();
                final hasPermission = await usageService.requestPermissions();
                
                if (hasPermission) {
                  await usageService.startTracking();
                  await MLService().initialize();
                }
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}