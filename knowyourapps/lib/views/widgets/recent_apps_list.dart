import 'package:flutter/material.dart';
import '../../models/app_usage_model.dart';
import 'app_usage_card.dart';

class RecentAppsList extends StatelessWidget {
  final List<AppUsageRecord> recentApps;
  final VoidCallback? onViewAll;

  const RecentAppsList({
    Key? key,
    required this.recentApps,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...recentApps.map((app) => AppUsageCard(
          appUsage: app,
          onTap: () {
            // Show app details
            _showAppDetailsDialog(context, app);
          },
        )).toList(),
        if (recentApps.isNotEmpty)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  void _showAppDetailsDialog(BuildContext context, AppUsageRecord app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Package', app.packageName),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Used On', 
              '${_formatDate(app.startTime)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Duration', 
              _formatDuration(app.endTime.difference(app.startTime)),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Category', app.category),
            if (app.location != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Location', app.location!),
            ],
            if (app.metadata != null && app.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Additional Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...app.metadata!.entries.map((entry) => 
                _buildDetailRow(entry.key, entry.value.toString())
              ).toList(),
            ],
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}