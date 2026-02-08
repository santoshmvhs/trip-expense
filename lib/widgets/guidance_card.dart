import 'package:flutter/material.dart';
import '../../features/moments/data/models/guidance.dart';
import '../app/theme.dart';

class GuidanceCard extends StatelessWidget {
  final Guidance guidance;
  
  const GuidanceCard({
    super.key,
    required this.guidance,
  });
  
  @override
  Widget build(BuildContext context) {
    if (guidance.nudges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                'All good! No actions needed.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MomentraColors.warmOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: MomentraColors.warmOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Suggested Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...guidance.nudges.map((nudge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getIconForPriority(nudge.priority),
                    size: 16,
                    color: _getColorForPriority(nudge.priority),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nudge.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
  
  Color _getColorForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return HealthColors.red;
      case 'medium':
        return MomentraColors.warmOrange;
      default:
        return HealthColors.green;
    }
  }
}

