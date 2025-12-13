import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/group_budget.dart';
import '../../core/models/user_budget.dart';
import '../../core/models/expense_split.dart';
import '../../core/providers/expense_with_splits_provider.dart';

class BudgetCard extends StatelessWidget {
  final dynamic budget; // GroupBudget or UserBudget
  final bool isGroupBudget;
  final String groupCurrency;
  final List<dynamic> expenses; // List<Expense>
  final List<ExpenseWithSplits> expensesWithSplits; // List<ExpenseWithSplits>
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.isGroupBudget,
    required this.groupCurrency,
    required this.expenses,
    this.expensesWithSplits = const [],
    this.onEdit,
    this.onDelete,
  });

  double _calculateSpent() {
    if (expenses.isEmpty) return 0.0;

    double total = 0.0;
    final budgetCategory = budget.category;

    for (var expense in expenses) {
      // If budget has a category, only count expenses in that category
      if (budgetCategory != null && expense.category != budgetCategory) {
        continue;
      }

      // Check date range if budget has dates
      if (budget.startDate != null || budget.endDate != null) {
        final expenseDate = expense.expenseDate;
        if (budget.startDate != null && expenseDate.isBefore(budget.startDate!)) {
          continue;
        }
        if (budget.endDate != null && expenseDate.isAfter(budget.endDate!)) {
          continue;
        }
      }

      // For group budgets, count all expenses
      // For user budgets, count only expenses where user is involved
      if (isGroupBudget) {
        total += expense.amount;
      } else {
        // Count user's share from expense splits
        final userBudget = budget as UserBudget;
        
        // Find expense with splits
        final expenseWithSplits = expensesWithSplits.firstWhere(
          (e) => e.expense.id == expense.id,
          orElse: () => ExpenseWithSplits(expense: expense, splits: []),
        );
        
        // If user paid, count full amount
        if (expense.paidBy == userBudget.userId) {
          total += expense.amount;
        } else {
          // Otherwise, count user's share from splits
          final userSplit = expenseWithSplits.splits.firstWhere(
            (split) => split.userId == userBudget.userId,
            orElse: () => ExpenseSplit(
              expenseId: expense.id,
              userId: userBudget.userId,
              share: 0.0,
            ),
          );
          total += userSplit.share;
        }
      }
    }

    return total;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: _getCurrencySymbol(budget.currency ?? groupCurrency),
      decimalDigits: 2,
    ).format(amount);
  }

  String _getCurrencySymbol(String currency) {
    final symbols = {
      'INR': '₹',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
    };
    return symbols[currency.toUpperCase()] ?? currency;
  }

  @override
  Widget build(BuildContext context) {
    final spent = _calculateSpent();
    final budgetAmount = budget.amount;
    final remaining = budgetAmount - spent;
    final percentage = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0.0;
    final isOverBudget = remaining < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGroupBudget ? Icons.group : Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.description ?? (isGroupBudget ? 'Trip Budget' : 'Personal Budget'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (budget.category != null) ...[
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(budget.category!),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          onTap: onEdit,
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          onTap: onDelete,
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(budgetAmount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Spent',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(spent),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage > 100 ? 1.0 : percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? Colors.red
                    : percentage > 80
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  isOverBudget
                      ? 'Over by ${_formatCurrency(-remaining)}'
                      : '${_formatCurrency(remaining)} remaining',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverBudget ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (budget.startDate != null || budget.endDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    final start = budget.startDate;
    final end = budget.endDate;
    if (start != null && end != null) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(end)}';
    } else if (start != null) {
      return 'From ${DateFormat('MMM d, y').format(start)}';
    } else if (end != null) {
      return 'Until ${DateFormat('MMM d, y').format(end)}';
    }
    return '';
  }
}

