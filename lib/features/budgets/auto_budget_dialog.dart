import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/expense.dart';
import '../../core/models/expense_split.dart';
import '../../core/providers/expense_providers.dart';
import '../../core/providers/expense_with_splits_provider.dart';
import '../../core/providers/budget_providers.dart';
import '../../core/supabase/supabase_client.dart';

class AutoBudgetDialog extends ConsumerStatefulWidget {
  final String groupId;
  final String groupCurrency;
  final bool isGroupBudget;

  const AutoBudgetDialog({
    super.key,
    required this.groupId,
    required this.groupCurrency,
    required this.isGroupBudget,
  });

  @override
  ConsumerState<AutoBudgetDialog> createState() => _AutoBudgetDialogState();
}

class _AutoBudgetDialogState extends ConsumerState<AutoBudgetDialog> {
  Map<String, double> _suggestedBudgets = {};
  final Map<String, TextEditingController> _budgetControllers = {};
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _analyzeExpenses();
  }

  @override
  void dispose() {
    for (final controller in _budgetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _analyzeExpenses() async {
    setState(() => _isLoading = true);

    try {
      final expenses = await ref.read(groupExpensesProvider(widget.groupId).future);
      final expensesWithSplits = await ref.read(groupExpensesWithSplitsProvider(widget.groupId).future);
      final currentUserId = supabase().auth.currentUser?.id;

      // Group expenses by category and subcategory
      final categoryTotals = <String, double>{};
      final subcategoryTotals = <String, double>{};

      for (final expense in expenses) {
        if (expense.category != null) {
          double amountToCount = 0.0;

          if (widget.isGroupBudget) {
            // For group budgets, count full expense amount
            amountToCount = expense.amount;
          } else {
            // For user budgets, count user's share from splits
            if (currentUserId != null) {
              // Find expense with splits
              final expenseWithSplits = expensesWithSplits.firstWhere(
                (e) => e.expense.id == expense.id,
                orElse: () => ExpenseWithSplits(expense: expense, splits: []),
              );

              // If user paid, count full amount
              if (expense.paidBy == currentUserId) {
                amountToCount = expense.amount;
              } else {
                // Otherwise, count user's share from splits
                final userSplit = expenseWithSplits.splits.firstWhere(
                  (split) => split.userId == currentUserId,
                  orElse: () => ExpenseSplit(
                    expenseId: expense.id,
                    userId: currentUserId!,
                    share: 0.0,
                  ),
                );
                amountToCount = userSplit.share;
              }
            }
          }

          if (amountToCount > 0) {
            // Count for category budgets
            categoryTotals[expense.category!] =
                (categoryTotals[expense.category!] ?? 0) + amountToCount;

            // Count for subcategory budgets
            if (expense.subcategory != null) {
              final key = '${expense.category} - ${expense.subcategory}';
              subcategoryTotals[key] =
                  (subcategoryTotals[key] ?? 0) + amountToCount;
            }
          }
        }
      }

      // Calculate suggested budgets (add 20% buffer)
      final allSuggestions = <String, double>{};
      categoryTotals.forEach((category, total) {
        allSuggestions[category] = total * 1.2; // 20% buffer
        if (!_budgetControllers.containsKey(category)) {
          _budgetControllers[category] = TextEditingController(
            text: (total * 1.2).toStringAsFixed(2),
          );
        }
      });

      subcategoryTotals.forEach((subcategory, total) {
        allSuggestions[subcategory] = total * 1.2; // 20% buffer
        if (!_budgetControllers.containsKey(subcategory)) {
          _budgetControllers[subcategory] = TextEditingController(
            text: (total * 1.2).toStringAsFixed(2),
          );
        }
      });

      setState(() {
        _suggestedBudgets = allSuggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing expenses: $e')),
        );
      }
    }
  }

  Future<void> _createBudgets() async {
    if (_budgetControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No budgets to create')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(budgetsRepoProvider);
      final currentUserId = supabase().auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      int created = 0;
      for (final entry in _budgetControllers.entries) {
        final name = entry.key;
        final amount = double.tryParse(entry.value.text);
        if (amount == null || amount <= 0) continue;

        // Check if it's a subcategory (contains " - ")
        final isSubcategory = name.contains(' - ');
        final category = isSubcategory ? name.split(' - ')[0] : name;
        final subcategory = isSubcategory ? name.split(' - ')[1] : null;

        try {
          if (widget.isGroupBudget) {
            await repo.createGroupBudget(
              groupId: widget.groupId,
              createdBy: currentUserId,
              amount: amount,
              currency: widget.groupCurrency,
              category: category,
              description: subcategory != null
                  ? 'Budget for $category: $subcategory'
                  : 'Budget for $category',
            );
          } else {
            await repo.createUserBudget(
              groupId: widget.groupId,
              userId: currentUserId,
              amount: amount,
              currency: widget.groupCurrency,
              category: category,
              description: subcategory != null
                  ? 'Budget for $category: $subcategory'
                  : 'Budget for $category',
            );
          }
          created++;
        } catch (e) {
          debugPrint('Error creating budget for $name: $e');
          // Continue with other budgets
        }
      }

      if (mounted) {
        ref.invalidate(groupBudgetsProvider(widget.groupId));
        ref.invalidate(currentUserBudgetsProvider(widget.groupId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $created budget${created != 1 ? 's' : ''}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating budgets: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isGroupBudget
            ? 'Auto-Create Trip Budgets'
            : 'Auto-Create Personal Budgets',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _suggestedBudgets.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add expenses with categories to generate budgets',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Based on your expenses, we suggest these budgets:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ..._budgetControllers.entries.map((entry) {
                          final name = entry.key;
                          final suggested = _suggestedBudgets[name] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: name,
                                hintText: 'Budget amount',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixText: widget.groupCurrency,
                                helperText:
                                    'Suggested: ${NumberFormat.currency(symbol: '₹').format(suggested)}',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading || _isCreating || _suggestedBudgets.isEmpty
              ? null
              : _createBudgets,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Budgets'),
        ),
      ],
    );
  }
}

