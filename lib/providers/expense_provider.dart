import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../models/balance_model.dart';
import '../models/payment_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, List<ExpenseModel>> _expensesByGroup = {};
  Map<String, List<BalanceModel>> _balancesByGroup = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<ExpenseModel> getExpensesForGroup(String groupId) {
    return _expensesByGroup[groupId] ?? [];
  }

  List<BalanceModel> getBalancesForGroup(String groupId) {
    return _balancesByGroup[groupId] ?? [];
  }

  Future<void> loadExpenses(String groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final expenses = (response as List)
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Load splits for each expense
      for (var expense in expenses) {
        await loadExpenseSplits(expense);
      }

      _expensesByGroup[groupId] = expenses;
      await calculateBalances(groupId);
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpenseSplits(ExpenseModel expense) async {
    try {
      final response = await _supabase
          .from('expense_splits')
          .select()
          .eq('expense_id', expense.id);

      final splits = (response as List)
          .map((json) => ExpenseSplit.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update expense with splits
      final index = _expensesByGroup[expense.groupId]?.indexWhere((e) => e.id == expense.id);
      if (index != null && index >= 0) {
        _expensesByGroup[expense.groupId]![index] = ExpenseModel(
          id: expense.id,
          groupId: expense.groupId,
          paidBy: expense.paidBy,
          amount: expense.amount,
          currency: expense.currency,
          description: expense.description,
          category: expense.category,
          receiptUrl: expense.receiptUrl,
          isRecurring: expense.isRecurring,
          recurringFrequency: expense.recurringFrequency,
          recurringEndDate: expense.recurringEndDate,
          createdAt: expense.createdAt,
          updatedAt: expense.updatedAt,
          splits: splits,
        );
      }
    } catch (e) {
      debugPrint('Error loading expense splits: $e');
    }
  }

  Future<ExpenseModel> createExpense({
    required String groupId,
    required String paidBy,
    required double amount,
    required String description,
    String currency = 'USD',
    String? category,
    String? receiptUrl,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    required Map<String, double> splits, // userId -> amount
  }) async {
    try {
      // Create expense
      final expenseResponse = await _supabase.from('expenses').insert({
        'group_id': groupId,
        'paid_by': paidBy,
        'amount': amount,
        'currency': currency,
        'description': description,
        'category': category,
        'receipt_url': receiptUrl,
        'is_recurring': isRecurring,
        'recurring_frequency': recurringFrequency,
        'recurring_end_date': recurringEndDate?.toIso8601String(),
      }).select().single();

      final expense = ExpenseModel.fromJson(expenseResponse as Map<String, dynamic>);

      // Create splits
      final splitData = splits.entries.map((entry) => {
        'expense_id': expense.id,
        'user_id': entry.key,
        'amount': entry.value,
      }).toList();

      await _supabase.from('expense_splits').insert(splitData);

      // Reload expenses
      await loadExpenses(groupId);

      return expense;
    } catch (e) {
      debugPrint('Error creating expense: $e');
      rethrow;
    }
  }

  Future<void> calculateBalances(String groupId) async {
    try {
      // Get all expenses with splits
      final expenses = _expensesByGroup[groupId] ?? [];
      
      // Get group members
      final membersResponse = await _supabase
          .from('group_members')
          .select('user_id, profiles(full_name, email)')
          .eq('group_id', groupId);

      final balances = <String, BalanceModel>{};

      // Initialize balances
      for (var member in membersResponse as List) {
        final userId = member['user_id'] as String;
        final profile = member['profiles'] as Map<String, dynamic>;
        balances[userId] = BalanceModel(
          userId: userId,
          userName: profile['full_name'] ?? profile['email'] ?? 'Unknown',
          balance: 0,
        );
      }

      // Calculate balances from expenses
      for (var expense in expenses) {
        // Person who paid gets credited
        if (balances.containsKey(expense.paidBy)) {
          balances[expense.paidBy] = BalanceModel(
            userId: balances[expense.paidBy]!.userId,
            userName: balances[expense.paidBy]!.userName,
            balance: balances[expense.paidBy]!.balance + expense.amount,
          );
        }

        // People who owe get debited
        for (var split in expense.splits) {
          if (balances.containsKey(split.userId)) {
            balances[split.userId] = BalanceModel(
              userId: balances[split.userId]!.userId,
              userName: balances[split.userId]!.userName,
              balance: balances[split.userId]!.balance - split.amount,
            );
          }
        }
      }

      // Subtract payments
      final paymentsResponse = await _supabase
          .from('payments')
          .select()
          .eq('group_id', groupId);

      for (var paymentJson in paymentsResponse as List) {
        final payment = PaymentModel.fromJson(paymentJson as Map<String, dynamic>);
        
        // Payer pays (debit)
        if (balances.containsKey(payment.payerId)) {
          balances[payment.payerId] = BalanceModel(
            userId: balances[payment.payerId]!.userId,
            userName: balances[payment.payerId]!.userName,
            balance: balances[payment.payerId]!.balance - payment.amount,
          );
        }

        // Payee receives (credit)
        if (balances.containsKey(payment.payeeId)) {
          balances[payment.payeeId] = BalanceModel(
            userId: balances[payment.payeeId]!.userId,
            userName: balances[payment.payeeId]!.userName,
            balance: balances[payment.payeeId]!.balance + payment.amount,
          );
        }
      }

      _balancesByGroup[groupId] = balances.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error calculating balances: $e');
    }
  }

  Future<void> recordPayment({
    required String groupId,
    required String payerId,
    required String payeeId,
    required double amount,
    String currency = 'USD',
    String? description,
  }) async {
    try {
      await _supabase.from('payments').insert({
        'group_id': groupId,
        'payer_id': payerId,
        'payee_id': payeeId,
        'amount': amount,
        'currency': currency,
        'description': description,
      });

      await calculateBalances(groupId);
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId, String groupId) async {
    try {
      await _supabase.from('expenses').delete().eq('id', expenseId);
      await loadExpenses(groupId);
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }
}

