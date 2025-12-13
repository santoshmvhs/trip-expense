import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/trip_budget.dart';
import '../../core/models/trip_budget_allocation.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/expense_with_splits_provider.dart';
import '../../core/repositories/budgets_repo.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/category_icons.dart';
import 'trip_budget_dialog.dart';

class TripBudgetPlanner extends ConsumerWidget {
  final String groupId;
  final String groupCurrency;
  final bool isAdmin;

  const TripBudgetPlanner({
    super.key,
    required this.groupId,
    required this.groupCurrency,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTripBudget = ref.watch(tripBudgetProvider(groupId));
    final asyncExpenses = ref.watch(groupExpensesProvider(groupId));

    return asyncTripBudget.when(
      data: (tripBudget) {
        if (tripBudget == null) {
          return _buildEmptyState(context, ref);
        }

        return asyncExpenses.when(
          data: (expenses) {
            return _buildTripBudgetView(context, ref, tripBudget, expenses);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading expenses')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading trip budget')),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    if (!isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trip budget set',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask an admin to create a trip budget',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No trip budget set',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a trip budget and allocate it across categories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTripBudgetDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Trip Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripBudgetView(
    BuildContext context,
    WidgetRef ref,
    TripBudget tripBudget,
    List expenses,
  ) {
    final asyncAllocations = ref.watch(tripBudgetAllocationsProvider(tripBudget.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tripBudgetProvider(groupId));
        ref.invalidate(tripBudgetAllocationsProvider(tripBudget.id));
        ref.invalidate(groupExpensesProvider(groupId));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Budget Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Budget',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditTripBudgetDialog(context, ref, tripBudget),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(tripBudget.totalAmount, tripBudget.currency),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    if (tripBudget.description != null && tripBudget.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        tripBudget.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Allocations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Allocations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: () => _showManageAllocationsDialog(context, ref, tripBudget),
                    icon: const Icon(Icons.add),
                    label: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            asyncAllocations.when(
              data: (allocations) {
                if (allocations.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No allocations yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _showManageAllocationsDialog(context, ref, tripBudget),
                                child: const Text('Add Allocations'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Calculate total allocated
                final totalAllocated = allocations.fold<double>(
                  0.0,
                  (sum, allocation) => sum + allocation.amount,
                );
                final remaining = tripBudget.totalAmount - totalAllocated;

                return Column(
                  children: [
                    // Summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allocated',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  _formatCurrency(totalAllocated, tripBudget.currency),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Remaining',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                Text(
                                  _formatCurrency(remaining, tripBudget.currency),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: remaining < 0 ? Colors.red : Colors.green,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Allocation List
                    ...allocations.map((allocation) {
                      return _buildAllocationCard(
                        context,
                        ref,
                        allocation,
                        tripBudget,
                        expenses,
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading allocations')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationCard(
    BuildContext context,
    WidgetRef ref,
    TripBudgetAllocation allocation,
    TripBudget tripBudget,
    List expenses,
  ) {
    // Calculate spent for this category/subcategory
    final spent = _calculateSpentForAllocation(expenses, allocation, tripBudget.currency);
    final percentage = allocation.amount > 0 ? (spent / allocation.amount) * 100 : 0.0;
    final isOverBudget = spent > allocation.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CategoryIcons.getIconForCategory(allocation.category ?? ''),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allocation.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (allocation.category != null && allocation.subcategory != null)
                        Text(
                          allocation.category!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  _formatCurrency(allocation.amount, tripBudget.currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            LinearProgressIndicator(
              value: percentage > 100 ? 1.0 : percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            // Spent vs Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${_formatCurrency(spent, tripBudget.currency)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverBudget ? Colors.red : Colors.grey[600],
                      ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverBudget ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSpentForAllocation(
    List expenses,
    TripBudgetAllocation allocation,
    String currency,
  ) {
    double total = 0.0;
    for (var expense in expenses) {
      // Match by category and subcategory
      final expenseCategory = expense.category as String?;
      final expenseSubcategory = expense.subcategory as String?;

      bool matches = false;
      if (allocation.subcategory != null && allocation.subcategory!.isNotEmpty) {
        // Match by subcategory
        matches = expenseSubcategory == allocation.subcategory;
      } else if (allocation.category != null && allocation.category!.isNotEmpty) {
        // Match by category
        matches = expenseCategory == allocation.category;
      }

      if (matches) {
        // Convert currency if needed (simplified - assumes same currency for now)
        total += expense.amount as double;
      }
    }
    return total;
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }

  Future<void> _showCreateTripBudgetDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => TripBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
      ),
    );
    ref.invalidate(tripBudgetProvider(groupId));
  }

  Future<void> _showEditTripBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    TripBudget tripBudget,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => TripBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
        tripBudget: tripBudget,
      ),
    );
    ref.invalidate(tripBudgetProvider(groupId));
  }

  Future<void> _showManageAllocationsDialog(
    BuildContext context,
    WidgetRef ref,
    TripBudget tripBudget,
  ) async {
    // This will be implemented in trip_budget_dialog.dart
    await showDialog(
      context: context,
      builder: (context) => TripBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
        tripBudget: tripBudget,
        showAllocations: true,
      ),
    );
    ref.invalidate(tripBudgetAllocationsProvider(tripBudget.id));
  }
}

