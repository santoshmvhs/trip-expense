import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';
import '../supabase/supabase_client.dart';
import 'expense_providers.dart';

// Extended expense model with splits
class ExpenseWithSplits {
  final Expense expense;
  final List<ExpenseSplit> splits;

  ExpenseWithSplits({
    required this.expense,
    required this.splits,
  });
}

// Provider that loads expenses with their splits
final groupExpensesWithSplitsProvider = FutureProvider.family<List<ExpenseWithSplits>, String>((ref, groupId) async {
  final expensesRepo = ref.watch(expensesRepoProvider);
  final expenses = await expensesRepo.listGroupExpenses(groupId);
  
  // Load splits for each expense
  final expensesWithSplits = <ExpenseWithSplits>[];
  
  for (final expense in expenses) {
    try {
      final splitsRes = await supabase()
          .from('expense_splits')
          .select()
          .eq('expense_id', expense.id);
      
      final splits = (splitsRes as List)
          .map((e) => ExpenseSplit.fromJson(e as Map<String, dynamic>))
          .toList();
      
      expensesWithSplits.add(ExpenseWithSplits(
        expense: expense,
        splits: splits,
      ));
    } catch (e) {
      // If splits fail to load, still include expense with empty splits
      expensesWithSplits.add(ExpenseWithSplits(
        expense: expense,
        splits: [],
      ));
    }
  }
  
  return expensesWithSplits;
});

