import 'package:flutter/material.dart';
import '../../models/app_usage_model.dart';

class AppUsageCard extends StatelessWidget {
  final AppUsageRecord appUsage;
  final VoidCallback? onTap;

  const AppUsageCard({
    Key? key,
    required this.appUsage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate duration in minutes
    final duration = appUsage.endTime.difference(appUsage.startTime);
    final minutes = duration.inMinutes;
    final hours = duration.inHours;
    
    // Format duration string
    final durationString = hours > 0 
        ? '${hours}h ${minutes % 60}m' 
        : '${minutes}m';
    
    // Format time string
    final timeString = '${_formatTime(appUsage.startTime)} - ${_formatTime(appUsage.endTime)}';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // App icon placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(appUsage.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    appUsage.appName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // App info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appUsage.appName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appUsage.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeString,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      durationString,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _getCategoryColor(String category) {
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
        return Colors.grey;
    }
  }
}