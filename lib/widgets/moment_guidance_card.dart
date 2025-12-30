import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/models/moment_guidance.dart';

class MomentGuidanceCard extends StatelessWidget {
  final MomentGuidance guidance;
  
  const MomentGuidanceCard({
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
              const Icon(Icons.check_circle, color: HealthColors.green),
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
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ...guidance.nudges.map((nudge) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getIconForPriority(nudge.priority),
                    size: 18,
                    color: _getColorForPriority(nudge.priority),
                  ),
                  const SizedBox(width: 12),
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
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
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

