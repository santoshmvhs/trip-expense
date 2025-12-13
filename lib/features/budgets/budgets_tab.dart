import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/group_budget.dart';
import '../../core/models/user_budget.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/expense_with_splits_provider.dart';
import '../../core/supabase/supabase_client.dart';
import 'add_budget_dialog.dart';
import 'auto_budget_dialog.dart';
import 'budget_card.dart';
import 'trip_budget_planner.dart';

class BudgetsTab extends ConsumerWidget {
  final String groupId;
  final String groupCurrency;
  final String? groupCreatedBy; // To check if user is creator

  const BudgetsTab({
    super.key,
    required this.groupId,
    required this.groupCurrency,
    this.groupCreatedBy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroupBudgets = ref.watch(groupBudgetsProvider(groupId));
    final asyncUserBudgets = ref.watch(currentUserBudgetsProvider(groupId));
    final asyncExpenses = ref.watch(groupExpensesProvider(groupId));
    final asyncExpensesWithSplits = ref.watch(groupExpensesWithSplitsProvider(groupId));
    final currentUserId = supabase().auth.currentUser?.id;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.group), text: 'Trip Budget'),
              Tab(icon: Icon(Icons.person), text: 'My Budget'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Trip Budget Planner Tab
                TripBudgetPlanner(
                  groupId: groupId,
                  groupCurrency: groupCurrency,
                  isAdmin: currentUserId == groupCreatedBy,
                ),
                // User Budgets Tab
                _buildUserBudgetsTab(
                  context,
                  ref,
                  asyncUserBudgets,
                  asyncExpenses,
                  asyncExpensesWithSplits,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBudgetsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GroupBudget>> asyncBudgets,
    AsyncValue<List> asyncExpenses,
    AsyncValue<List> asyncExpensesWithSplits,
    String? currentUserId,
  ) {
    final isAdmin = currentUserId == groupCreatedBy; // Simplified - could check group_members table
    
    return asyncBudgets.when(
      data: (budgets) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupBudgetsProvider(groupId));
            ref.invalidate(groupExpensesProvider(groupId));
            ref.invalidate(groupExpensesWithSplitsProvider(groupId));
          },
          child: budgets.isEmpty && !isAdmin
              ? Center(
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
                        'No trip budgets set',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admins can create budgets for the trip',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length + (isAdmin ? 1 : 0), // +1 for add button
                  itemBuilder: (context, index) {
                    if (isAdmin && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _showAddBudgetDialog(context, ref, true),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Budget'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showAutoBudgetDialog(context, ref, true),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Auto'),
                            ),
                          ],
                        ),
                      );
                    }
                    final budgetIndex = isAdmin ? index - 1 : index;
                    final budget = budgets[budgetIndex];
                    return BudgetCard(
                      budget: budget,
                      isGroupBudget: true,
                      groupCurrency: groupCurrency,
                      expenses: asyncExpenses.valueOrNull ?? [],
                      expensesWithSplits: asyncExpensesWithSplits.valueOrNull?.cast<ExpenseWithSplits>() ?? <ExpenseWithSplits>[],
                      onEdit: currentUserId == budget.createdBy || isAdmin
                          ? () => _showEditBudgetDialog(context, ref, budget, null)
                          : null,
                      onDelete: currentUserId == budget.createdBy || isAdmin
                          ? () => _deleteBudget(context, ref, budget.id, true)
                          : null,
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading budgets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(groupBudgetsProvider(groupId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBudgetsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<UserBudget>> asyncBudgets,
    AsyncValue<List> asyncExpenses,
    AsyncValue<List> asyncExpensesWithSplits,
  ) {
    return asyncBudgets.when(
      data: (budgets) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserBudgetsProvider(groupId));
            ref.invalidate(groupExpensesProvider(groupId));
            ref.invalidate(groupExpensesWithSplitsProvider(groupId));
          },
          child: budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No personal budgets set',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set your personal budget for this trip',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showAddBudgetDialog(context, ref, false),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Budget'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showAutoBudgetDialog(context, ref, false),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Auto'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length + 1, // +1 for add button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _showAddBudgetDialog(context, ref, false),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Budget'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showAutoBudgetDialog(context, ref, false),
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Auto'),
                            ),
                          ],
                        ),
                      );
                    }
                    final budget = budgets[index - 1];
                    return BudgetCard(
                      budget: budget,
                      isGroupBudget: false,
                      groupCurrency: groupCurrency,
                      expenses: asyncExpenses.valueOrNull ?? [],
                      expensesWithSplits: asyncExpensesWithSplits.valueOrNull?.cast<ExpenseWithSplits>() ?? <ExpenseWithSplits>[],
                      onEdit: () => _showEditBudgetDialog(context, ref, null, budget),
                      onDelete: () => _deleteBudget(context, ref, budget.id, false),
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading budgets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(currentUserBudgetsProvider(groupId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref, bool isGroupBudget) {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
        isGroupBudget: isGroupBudget,
        onSaved: () {
          ref.invalidate(groupBudgetsProvider(groupId));
          ref.invalidate(currentUserBudgetsProvider(groupId));
        },
      ),
    );
  }

  void _showAutoBudgetDialog(BuildContext context, WidgetRef ref, bool isGroupBudget) {
    showDialog(
      context: context,
      builder: (context) => AutoBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
        isGroupBudget: isGroupBudget,
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    GroupBudget? groupBudget,
    UserBudget? userBudget,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(
        groupId: groupId,
        groupCurrency: groupCurrency,
        isGroupBudget: groupBudget != null,
        groupBudget: groupBudget,
        userBudget: userBudget,
        onSaved: () {
          ref.invalidate(groupBudgetsProvider(groupId));
          ref.invalidate(currentUserBudgetsProvider(groupId));
        },
      ),
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    WidgetRef ref,
    String budgetId,
    bool isGroupBudget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(budgetsRepoProvider);
        if (isGroupBudget) {
          await repo.deleteGroupBudget(budgetId);
        } else {
          await repo.deleteUserBudget(budgetId);
        }
        ref.invalidate(groupBudgetsProvider(groupId));
        ref.invalidate(currentUserBudgetsProvider(groupId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting budget: $e')),
          );
        }
      }
    }
  }
}

