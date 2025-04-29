import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_state.dart';
import '../widgets/mood_slider.dart';
import '../widgets/app_usage_card.dart';
import '../widgets/recent_apps_list.dart';
import '../widgets/mood_insight_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Know Your Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Refresh data
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.refreshUsageData();
              await appState.generateMoodPrediction();
              
              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.refreshUsageData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildCurrentMoodSection(context),
                const SizedBox(height: 24),
                _buildTodayUsageSection(context),
                const SizedBox(height: 24),
                _buildRecentAppsSection(context),
                const SizedBox(height: 24),
                _buildInsightsSection(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMoodSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            MoodSlider(
              initialValue: appState.currentMoodScore,
              onChanged: (value) {
                // Do nothing on change
              },
              onChangeEnd: (value) async {
                // Show dialog to get explanation
                final explanation = await _showMoodFeedbackDialog(context, value);
                
                // Save mood feedback
                if (explanation != null) {
                  await appState.provideMoodFeedback(value, explanation: explanation);
                } else {
                  await appState.provideMoodFeedback(value);
                }
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getMoodDescription(appState.currentMoodScore),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayUsageSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Calculate total usage time
        final Duration totalUsage = _calculateTotalUsageTime(appState.dailyUsage);
        final String usageDisplay = _formatDuration(totalUsage);
        
        // Get most used category
        final String mostUsedCategory = _getMostUsedCategory(appState.dailyUsage);
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Usage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Total Time',
                      usageDisplay,
                      Icons.access_time,
                    ),
                    _buildStatItem(
                      context,
                      'Most Used',
                      mostUsedCategory,
                      Icons.category,
                    ),
                    _buildStatItem(
                      context,
                      'App Count',
                      appState.dailyUsage.length.toString(),
                      Icons.apps,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentAppsSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recently Used Apps',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (appState.isLoadingUsage)
              const Center(child: CircularProgressIndicator())
            else if (appState.recentUsage.isEmpty)
              const Center(
                child: Text('No recent app usage data available.'),
              )
            else
              RecentAppsList(
                recentApps: appState.recentUsage.take(5).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (appState.isLoadingMoodPredictions)
              const Center(child: CircularProgressIndicator())
            else if (appState.latestMoodPrediction == null)
              const Center(
                child: Text('No mood prediction data available.'),
              )
            else
              MoodInsightCard(
                prediction: appState.latestMoodPrediction!,
                positiveApps: appState.topPositiveApps,
                negativeApps: appState.topNegativeApps,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Duration _calculateTotalUsageTime(List<AppUsageRecord> usageRecords) {
    int totalSeconds = 0;
    for (var record in usageRecords) {
      totalSeconds += record.endTime.difference(record.startTime).inSeconds;
    }
    return Duration(seconds: totalSeconds);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getMostUsedCategory(List<AppUsageRecord> usageRecords) {
    if (usageRecords.isEmpty) {
      return 'None';
    }
    
    // Group by category
    final Map<String, int> categoryDurations = {};
    
    for (var record in usageRecords) {
      final duration = record.endTime.difference(record.startTime).inSeconds;
      categoryDurations[record.category] = 
          (categoryDurations[record.category] ?? 0) + duration;
    }
    
    // Find the category with max duration
    String topCategory = 'Unknown';
    int maxDuration = 0;
    
    categoryDurations.forEach((category, duration) {
      if (duration > maxDuration) {
        maxDuration = duration;
        topCategory = category;
      }
    });
    
    return topCategory;
  }

  String _getMoodDescription(int moodScore) {
    if (moodScore >= 8) {
      return 'Excellent!';
    } else if (moodScore >= 5) {
      return 'Good';
    } else if (moodScore >= 2) {
      return 'Positive';
    } else if (moodScore >= -1) {
      return 'Neutral';
    } else if (moodScore >= -4) {
      return 'Negative';
    } else if (moodScore >= -7) {
      return 'Bad';
    } else {
      return 'Very Bad';
    }
  }

  Future<String?> _showMoodFeedbackDialog(BuildContext context, int moodScore) async {
    final TextEditingController _explanationController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mood Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You rated your mood as ${_getMoodDescription(moodScore)} ($moodScore).'),
            const SizedBox(height: 16),
            const Text('Would you like to provide more details?'),
            const SizedBox(height: 8),
            TextField(
              controller: _explanationController,
              decoration: const InputDecoration(
                hintText: 'Optional explanation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _explanationController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}