import 'package:flutter/material.dart';
import '../../models/mood_prediction_model.dart';

class MoodInsightCard extends StatelessWidget {
  final MoodPrediction prediction;
  final List<AppImpactScore> positiveApps;
  final List<AppImpactScore> negativeApps;

  const MoodInsightCard({
    Key? key,
    required this.prediction,
    required this.positiveApps,
    required this.negativeApps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(
                  _getMoodIcon(prediction.score),
                  size: 28,
                  color: _getMoodColor(prediction.score),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMoodTitle(prediction.score),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getMoodColor(prediction.score),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMoodColor(prediction.score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    prediction.score.toString(),
                    style: TextStyle(
                      color: _getMoodColor(prediction.score),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (prediction.explanation != null && prediction.explanation!.isNotEmpty)
              Text(
                prediction.explanation!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 24),
            if (positiveApps.isNotEmpty) ...[
              Text(
                'Apps with Positive Impact',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...positiveApps.take(3).map((app) => _buildAppImpactRow(
                context,
                app.appName,
                app.impactScore,
                positive: true,
              )).toList(),
            ],
            const SizedBox(height: 16),
            if (negativeApps.isNotEmpty) ...[
              Text(
                'Apps with Negative Impact',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...negativeApps.take(3).map((app) => _buildAppImpactRow(
                context,
                app.appName,
                app.impactScore.abs(),
                positive: false,
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppImpactRow(
    BuildContext context,
    String appName,
    double impact,
    {required bool positive}
  ) {
    final Color color = positive ? Colors.green : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            positive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              appName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              impact.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

  String _getMoodTitle(int score) {
    if (score >= 8) {
      return 'Excellent Mood';
    } else if (score >= 5) {
      return 'Good Mood';
    } else if (score >= 0) {
      return 'Positive Mood';
    } else if (score >= -5) {
      return 'Neutral/Mixed Mood';
    } else if (score >= -8) {
      return 'Negative Mood';
    } else {
      return 'Very Negative Mood';
    }
  }
}