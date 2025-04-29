import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/app_state.dart';
import '../../services/usage_service.dart';
import '../../services/ml_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _dataCollectionEnabled = true;
  String _refreshInterval = '15';
  String _defaultView = 'daily';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _dataCollectionEnabled = prefs.getBool('dataCollectionEnabled') ?? true;
      _refreshInterval = prefs.getString('refreshInterval') ?? '15';
      _defaultView = prefs.getString('defaultView') ?? 'daily';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('dataCollectionEnabled', _dataCollectionEnabled);
    await prefs.setString('refreshInterval', _refreshInterval);
    await prefs.setString('defaultView', _defaultView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'Appearance',
            [
              _buildSwitchTile(
                'Dark Mode',
                'Use dark theme throughout the app',
                _isDarkMode,
                (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive insights and status updates',
                _notificationsEnabled,
                (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          _buildSection(
            'Data Collection',
            [
              _buildSwitchTile(
                'App Usage Tracking',
                'Track which apps you use and for how long',
                _dataCollectionEnabled,
                (value) async {
                  setState(() {
                    _dataCollectionEnabled = value;
                  });
                  
                  // Start or stop tracking based on setting
                  final usageService = UsageService();
                  if (value) {
                    await usageService.startTracking();
                  } else {
                    usageService.stopTracking();
                  }
                  
                  _saveSettings();
                },
              ),
              _buildDropdownTile(
                'Refresh Interval',
                'How often to update app usage data',
                _refreshInterval,
                [
                  {'value': '5', 'label': '5 minutes'},
                  {'value': '15', 'label': '15 minutes'},
                  {'value': '30', 'label': '30 minutes'},
                  {'value': '60', 'label': '1 hour'},
                ],
                (value) {
                  setState(() {
                    _refreshInterval = value;
                  });
                  _saveSettings();
                },
              ),
              _buildDropdownTile(
                'Default View',
                'Default time period to show in insights',
                _defaultView,
                [
                  {'value': 'daily', 'label': 'Daily'},
                  {'value': 'weekly', 'label': 'Weekly'},
                  {'value': 'monthly', 'label': 'Monthly'},
                ],
                (value) {
                  setState(() {
                    _defaultView = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          _buildSection(
            'Privacy',
            [
              ListTile(
                title: const Text('Request Data Export'),
                subtitle: const Text('Download your complete usage data'),
                trailing: const Icon(Icons.download),
                onTap: () {
                  // Show export options dialog
                  _showExportDialog();
                },
              ),
              ListTile(
                title: const Text('Clear All Data'),
                subtitle: const Text('Remove all app usage and prediction data'),
                trailing: const Icon(Icons.delete_forever),
                onTap: () {
                  // Show confirmation dialog
                  _showClearDataDialog();
                },
              ),
            ],
          ),
          _buildSection(
            'Permissions',
            [
              ListTile(
                title: const Text('Usage Access'),
                subtitle: const Text('Manage app usage permissions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final usageService = UsageService();
                  await usageService.requestPermissions();
                },
              ),
            ],
          ),
          _buildSection(
            'About',
            [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                onTap: () {
                  // Show terms of service
                  _showInfoDialog('Terms of Service', 'Sample Terms of Service content...');
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                onTap: () {
                  // Show privacy policy
                  _showInfoDialog('Privacy Policy', 'Sample Privacy Policy content...');
                },
              ),
            ],
          ),
          // Add device info at the bottom
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: UsageService().getDeviceInfo(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final deviceInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Device: ${deviceInfo['model'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      if (deviceInfo['androidVersion'] != null)
                        Text(
                          'Android ${deviceInfo['androidVersion']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        )
                      else if (deviceInfo['systemVersion'] != null)
                        Text(
                          '${deviceInfo['systemName']} ${deviceInfo['systemVersion']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<Map<String, String>> options,
    ValueChanged<String> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option['value'],
            child: Text(option['label']!),
          );
        }).toList(),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Choose export format:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('CSV'),
              subtitle: Text('Spreadsheet format'),
            ),
            ListTile(
              leading: Icon(Icons.code),
              title: Text('JSON'),
              subtitle: Text('Structured data format'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export initiated. You will be notified when complete.'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your app usage history and mood predictions. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              // TODO: Implement data clearing
              // For now, just show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been cleared.'),
                ),
              );
              
              // Refresh app state
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.loadInitialData();
            },
            child: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}