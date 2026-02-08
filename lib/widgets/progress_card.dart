import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';

class ProgressCard extends StatelessWidget {
  final double currentAmount;
  final double targetAmount;
  final DateTime endDate;
  
  const ProgressCard({
    super.key,
    required this.currentAmount,
    required this.targetAmount,
    required this.endDate,
  });
  
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: MomentraColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 
                      ? HealthColors.green 
                      : MomentraColors.warmOrange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MomentraColors.warmOrange,
                  ),
                ),
                Text(
                  '${formatter.format(currentAmount)} / ${formatter.format(targetAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ends: ${DateFormat('MMM d, y').format(endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

