import 'dart:async';
import 'dart:io';
import 'package:app_usage/app_usage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_usage_model.dart';
import 'database_service.dart';

class UsageService {
  static final UsageService _instance = UsageService._internal();
  final DatabaseService _dbService = DatabaseService();
  
  // Track whether we have permissions
  bool _hasPermission = false;
  
  // For periodic updates
  Timer? _periodicUpdateTimer;
  
  // Last fetch timestamp to avoid duplicate data
  DateTime _lastFetchTimestamp = DateTime.now().subtract(const Duration(days: 1));

  factory UsageService() => _instance;

  UsageService._internal();

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final permissionStatus = await Permission.usageStats.request();
      _hasPermission = permissionStatus.isGranted;
      return _hasPermission;
    } else if (Platform.isIOS) {
      // iOS doesn't have explicit permission for screen time API
      // We'll know if we have access when we try to use it
      _hasPermission = true;
      return true;
    }
    return false;
  }

  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final permissionStatus = await Permission.usageStats.status;
      _hasPermission = permissionStatus.isGranted;
      return _hasPermission;
    } else if (Platform.isIOS) {
      // For iOS, we'll assume we have permission and handle errors when fetching
      return true;
    }
    return false;
  }

  Future<void> startTracking() async {
    // Check permissions first
    final hasPermission = await hasPermissions();
    if (!hasPermission) {
      throw Exception('Usage stats permission not granted');
    }

    // Fetch initial data
    await fetchAndStoreUsageData();
    
    // Set up periodic updates (every 15 minutes)
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => fetchAndStoreUsageData(),
    );
  }

  void stopTracking() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = null;
  }

  Future<void> fetchAndStoreUsageData() async {
    if (!_hasPermission) {
      final hasPermission = await hasPermissions();
      if (!hasPermission) {
        return;
      }
    }

    try {
      // Calculate time range for fetch (from last fetch until now)
      final now = DateTime.now();
      final startDate = _lastFetchTimestamp;
      _lastFetchTimestamp = now;
      
      // Get app usage stats
      final usageStats = await _getAppUsage(startDate, now);
      
      // Store in database
      for (var stat in usageStats) {
        await _dbService.insertAppUsage(stat);
      }
    } catch (e) {
      print('Error fetching usage data: $e');
      // Reset permission flag if permission-related error
      if (e.toString().contains('permission')) {
        _hasPermission = false;
      }
    }
  }

  Future<List<AppUsageRecord>> _getAppUsage(DateTime startDate, DateTime endDate) async {
    final List<AppUsageRecord> result = [];
    
    try {
      if (Platform.isAndroid) {
        // Android implementation using app_usage package
        final List<AppUsageInfo> usageInfo = await AppUsage().getAppUsage(startDate, endDate);
        
        for (var info in usageInfo) {
          // Skip system apps with very short usage times
          if (info.usage < const Duration(seconds: 5)) continue;
          
          final record = AppUsageRecord(
            packageName: info.packageName,
            appName: _getAppNameFromPackage(info.packageName),
            startTime: _estimateStartTime(endDate, info.usage),
            endTime: endDate,
            category: 'Unknown', // Will be categorized later
            metadata: {
              'usageDuration': info.usage.inSeconds,
            },
          );
          
          result.add(record);
        }
      } else if (Platform.isIOS) {
        // iOS implementation would use ScreenTime API
        // This is a placeholder as direct ScreenTime API access 
        // requires a native plugin which is beyond the scope of this example
        // In a real implementation, we'd call into native code here
      }
    } catch (e) {
      print('Error getting app usage: $e');
      rethrow;
    }
    
    return result;
  }

  DateTime _estimateStartTime(DateTime endTime, Duration usage) {
    return endTime.subtract(usage);
  }

  String _getAppNameFromPackage(String packageName) {
    // This is a simplistic implementation
    // In a real app, we would use the package manager to get the actual app name
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      return parts.last.replaceAllMapped(
        RegExp(r'([A-Z])'), 
        (match) => ' ${match.group(0)}'
      ).trim().capitalize();
    }
    return packageName;
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final Map<String, dynamic> info = {};
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
        info['androidVersion'] = androidInfo.version.release;
        info['sdkVersion'] = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['model'] = iosInfo.model;
        info['systemName'] = iosInfo.systemName;
        info['systemVersion'] = iosInfo.systemVersion;
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    
    return info;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}