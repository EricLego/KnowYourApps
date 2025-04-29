import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/app_state.dart';
import '../../models/mood_prediction_model.dart';
import '../../models/app_usage_model.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mood Trends'),
            Tab(text: 'App Usage'),
            Tab(text: 'Impact Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTrendsTab(),
          _buildAppUsageTab(),
          _buildImpactAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildMoodTrendsTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoadingMoodPredictions) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (appState.recentMoodPredictions.isEmpty) {
          return const Center(
            child: Text('No mood prediction data available yet.'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Mood Over Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: _buildMoodChart(appState.recentMoodPredictions),
              ),
              const SizedBox(height: 32),
              Text(
                'Mood Records',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...appState.recentMoodPredictions.take(5).map((prediction) => 
                _buildMoodRecordCard(prediction)
              ).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppUsageTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoadingUsage) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (appState.weeklyUsage.isEmpty) {
          return const Center(
            child: Text('No app usage data available yet.'),
          );
        }
        
        // Group by category
        final Map<String, Duration> categoryDurations = {};
        
        for (var record in appState.weeklyUsage) {
          final duration = record.endTime.difference(record.startTime);
          categoryDurations[record.category] = 
              (categoryDurations[record.category] ?? Duration.zero) + duration;
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly App Usage by Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: _buildCategoryPieChart(categoryDurations),
              ),
              const SizedBox(height: 32),
              Text(
                'Daily Usage Patterns',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _buildDailyUsageChart(appState.weeklyUsage),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImpactAnalysisTab() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoadingImpactScores) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final positiveApps = appState.topPositiveApps;
        final negativeApps = appState.topNegativeApps;
        
        if (positiveApps.isEmpty && negativeApps.isEmpty) {
          return const Center(
            child: Text('No app impact data available yet.'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apps with Most Positive Impact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (positiveApps.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No positive impact apps identified yet.'),
                )
              else
                SizedBox(
                  height: 200,
                  child: _buildImpactBarChart(positiveApps, positive: true),
                ),
              const SizedBox(height: 32),
              Text(
                'Apps with Most Negative Impact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (negativeApps.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No negative impact apps identified yet.'),
                )
              else
                SizedBox(
                  height: 200,
                  child: _buildImpactBarChart(negativeApps, positive: false),
                ),
              const SizedBox(height: 32),
              Text(
                'What This Means',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'The impact score shows how an app tends to affect your mood. '
                    'Positive scores suggest apps that correlate with improved mood, '
                    'while negative scores indicate apps that may contribute to reduced mood. '
                    'This analysis is based on your usage patterns and self-reported mood scores. '
                    'As you provide more feedback, the accuracy will improve over time.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodChart(List<MoodPrediction> predictions) {
    // Sort predictions by timestamp
    final sortedPredictions = [...predictions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Create line chart data
    final spots = sortedPredictions.map((prediction) {
      // Convert timestamp to x value in days
      final x = prediction.timestamp.millisecondsSinceEpoch.toDouble() / (1000 * 60 * 60 * 24);
      final y = prediction.score.toDouble();
      return FlSpot(x, y);
    }).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Convert the x value back to a date
                final date = DateTime.fromMillisecondsSinceEpoch(
                  (value * 1000 * 60 * 60 * 24).toInt()
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minY: -10,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
              return lineBarsSpot.map((spot) {
                // Get the corresponding prediction
                final index = spot.spotIndex;
                final prediction = sortedPredictions[index];
                
                return LineTooltipItem(
                  '${DateFormat('MM/dd hh:mm a').format(prediction.timestamp)}\n'
                  'Mood: ${prediction.score}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, Duration> categoryDurations) {
    // Convert to sections
    final sections = <PieChartSectionData>[];
    final totalDuration = categoryDurations.values.fold(
      Duration.zero,
      (prev, duration) => prev + duration,
    );
    
    int i = 0;
    categoryDurations.forEach((category, duration) {
      final percentage = duration.inSeconds / totalDuration.inSeconds;
      
      sections.add(
        PieChartSectionData(
          value: percentage * 100,
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          color: _getCategoryColor(category, i),
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      i++;
    });
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 0,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events if needed
          },
        ),
      ),
    );
  }

  Widget _buildDailyUsageChart(List<AppUsageRecord> usageRecords) {
    // Group by day
    final Map<int, Duration> dailyUsage = {};
    
    for (var record in usageRecords) {
      final day = record.startTime.weekday;
      final duration = record.endTime.difference(record.startTime);
      
      dailyUsage[day] = (dailyUsage[day] ?? Duration.zero) + duration;
    }
    
    // Create bar chart data
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 1; i <= 7; i++) {
      final hours = (dailyUsage[i]?.inMinutes ?? 0) / 60.0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              color: Colors.blue,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    weekdays[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '${value.toInt()}h',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              interval: 1,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = group.x;
              final weekdays = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
              final hours = rod.toY;
              
              return BarTooltipItem(
                '${weekdays[day]}\n${hours.toStringAsFixed(1)} hours',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImpactBarChart(List<AppImpactScore> apps, {required bool positive}) {
    final sortedApps = [...apps];
    if (positive) {
      sortedApps.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    } else {
      sortedApps.sort((a, b) => a.impactScore.compareTo(b.impactScore));
    }
    
    // Take top 5 apps
    final topApps = sortedApps.take(5).toList();
    
    // Create horizontal bar chart data
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < topApps.length; i++) {
      final app = topApps[i];
      final impact = positive ? app.impactScore : app.impactScore.abs();
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: impact,
              color: positive ? Colors.green : Colors.red,
              width: 16,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      );
    }
    
    return RotatedBox(
      quarterTurns: 1,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.center,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topApps.length) {
                    return RotatedBox(
                      quarterTurns: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return RotatedBox(
                    quarterTurns: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
                interval: 1,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topApps.length) {
                    return RotatedBox(
                      quarterTurns: 3,
                      child: SizedBox(
                        width: 120,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            topApps[index].appName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          maxY: 5,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x;
                if (index >= 0 && index < topApps.length) {
                  final app = topApps[index];
                  return BarTooltipItem(
                    '${app.appName}\nImpact: ${app.impactScore.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodRecordCard(MoodPrediction prediction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMoodIcon(prediction.score),
                  color: _getMoodColor(prediction.score),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mood: ${prediction.score}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getMoodColor(prediction.score),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(prediction.timestamp),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (prediction.explanation != null && prediction.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(prediction.explanation!),
            ],
            const SizedBox(height: 8),
            Text(
              prediction.isUserProvided 
                  ? 'Self-reported' 
                  : 'App-generated',
              style: TextStyle(
                fontSize: 12,
                color: prediction.isUserProvided
                    ? Colors.purple 
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(int score) {
    if (score >= 5) {
      return Icons.sentiment_very_satisfied;
    } else if (score >= 0) {
      return Icons.sentiment_satisfied;
    } else if (score >= -5) {
      return Icons.sentiment_neutral;
    } else {
      return Icons.sentiment_very_dissatisfied;
    }
  }

  Color _getMoodColor(int score) {
    if (score >= 5) {
      return Colors.green;
    } else if (score >= 0) {
      return Colors.lightGreen;
    } else if (score >= -5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getCategoryColor(String category, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.brown,
    ];
    
    switch (category) {
      case 'Social Media':
        return Colors.blue;
      case 'Productivity':
        return Colors.green;
      case 'Entertainment':
        return Colors.deepOrange;
      case 'Health & Fitness':
        return Colors.lightBlue;
      case 'Education':
        return Colors.purple;
      case 'News & Reading':
        return Colors.amber;
      case 'Games':
        return Colors.pink;
      case 'Utilities':
        return Colors.blueGrey;
      default:
        return colors[index % colors.length];
    }
  }
}