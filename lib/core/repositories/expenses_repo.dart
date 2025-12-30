import 'package:flutter/foundation.dart';
import '../supabase/supabase_client.dart';
import '../models/expense.dart';
import 'activities_repo.dart';
import 'package:intl/intl.dart';

class ExpensesRepo {
  Future<List<Expense>> listGroupExpenses(String groupId, {bool includePersonal = true}) async {
    final uid = currentUser()?.id;
    
    var query = supabase()
        .from('expenses')
        .select()
        .eq('group_id', groupId);
    
    // If includePersonal is false, filter out personal expenses (expenses with no splits)
    // Personal expenses are only visible to the creator
    if (!includePersonal && uid != null) {
      // Get all expense IDs that have splits
      final expensesWithSplits = await supabase()
          .from('expense_splits')
          .select('expense_id');
      
      final expenseIdsWithSplits = (expensesWithSplits as List)
          .map((e) => e['expense_id'] as String)
          .toSet();
      
      // Filter: show expenses that either have splits OR are created by current user
      // This way personal expenses are only visible to their creator
      final allExpenses = await query.order('expense_date', ascending: true)
          .order('created_at', ascending: true);
      
      final filtered = (allExpenses as List).where((e) {
        final expenseId = e['id'] as String;
        final createdBy = e['created_by'] as String?;
        // Show if it has splits (shared) OR if it's created by current user (personal)
        return expenseIdsWithSplits.contains(expenseId) || createdBy == uid;
      }).toList();
      
      return filtered.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
    }
    
    final res = await query
        .order('expense_date', ascending: true)
        .order('created_at', ascending: true);

    return (res as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required DateTime expenseDate,
    String? notes,
    String? receiptPath,
    String? category,
    String? subcategory,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    required Map<String, double> splitsByUserId, // userId -> share amount
    String? momentId, // Optional: link to moment
  }) async {
    final uid = currentUser()!.id;

    try {
      // Build insert data
      final insertData = <String, dynamic>{
        'group_id': groupId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'paid_by': paidBy,
        'created_by': uid,
        'expense_date': expenseDate.toIso8601String().substring(0, 10),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (receiptPath != null && receiptPath.isNotEmpty) 'receipt_path': receiptPath,
        if (category != null && category.isNotEmpty) 'category': category,
        if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
        // Recurring fields (if needed in future)
        if (isRecurring) 'is_recurring': isRecurring,
        if (recurringFrequency != null && recurringFrequency.isNotEmpty) 
          'recurring_frequency': recurringFrequency,
        if (recurringEndDate != null) 
          'recurring_end_date': recurringEndDate.toIso8601String(),
        // Moment link
        if (momentId != null && momentId.isNotEmpty) 'moment_id': momentId,
      };

      final inserted = await supabase()
          .from('expenses')
          .insert(insertData)
          .select()
          .single();

      final expenseId = inserted['id'] as String;
      final splitRows = splitsByUserId.entries
          .map((e) => {
                'expense_id': expenseId,
                'user_id': e.key,
                'share': e.value,
              })
          .toList();

      if (splitRows.isNotEmpty) {
        await supabase().from('expense_splits').insert(splitRows);
      }

      // Create activity for expense added
      final activitiesRepo = ActivitiesRepo();
      final currencySymbol = currency == 'INR' ? '₹' : currency;
      await activitiesRepo.createActivity(
        groupId: groupId,
        userId: uid,
        activityType: 'expense_added',
        description: '$currencySymbol${amount.toStringAsFixed(2)} - $title',
        relatedId: expenseId,
      );

      return Expense.fromJson(inserted as Map<String, dynamic>);
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Error creating expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Expense> getExpense(String expenseId) async {
    final res = await supabase()
        .from('expenses')
        .select()
        .eq('id', expenseId)
        .single();

    return Expense.fromJson(res as Map<String, dynamic>);
  }

  Future<Expense> updateExpense({
    required String expenseId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required DateTime expenseDate,
    String? notes,
    String? receiptPath,
    String? category,
    String? subcategory,
    bool isRecurring = false,
    String? recurringFrequency,
    DateTime? recurringEndDate,
    required Map<String, double> splitsByUserId,
  }) async {
    final uid = currentUser()!.id;

    try {
      // Build update data
      final updateData = <String, dynamic>{
        'title': title,
        'amount': amount,
        'currency': currency,
        'paid_by': paidBy,
        'expense_date': expenseDate.toIso8601String().substring(0, 10),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (receiptPath != null && receiptPath.isNotEmpty) 'receipt_path': receiptPath,
        if (category != null && category.isNotEmpty) 'category': category,
        if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
        if (isRecurring) 'is_recurring': isRecurring,
        if (recurringFrequency != null && recurringFrequency.isNotEmpty) 
          'recurring_frequency': recurringFrequency,
        if (recurringEndDate != null) 
          'recurring_end_date': recurringEndDate.toIso8601String(),
      };

      // Update expense
      final updated = await supabase()
          .from('expenses')
          .update(updateData)
          .eq('id', expenseId)
          .select()
          .single();

      // Delete old splits
      await supabase().from('expense_splits').delete().eq('expense_id', expenseId);

      // Insert new splits
      final splitRows = splitsByUserId.entries
          .map((e) => {
                'expense_id': expenseId,
                'user_id': e.key,
                'share': e.value,
              })
          .toList();

      if (splitRows.isNotEmpty) {
        await supabase().from('expense_splits').insert(splitRows);
      }

      // Create activity for expense updated
      final activitiesRepo = ActivitiesRepo();
      final currencySymbol = currency == 'INR' ? '₹' : currency;
      await activitiesRepo.createActivity(
        groupId: updated['group_id'] as String,
        userId: uid,
        activityType: 'expense_updated',
        description: '$currencySymbol${amount.toStringAsFixed(2)} - $title',
        relatedId: expenseId,
      );

      return Expense.fromJson(updated as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('Error updating expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final uid = currentUser()!.id;
    
    // Get expense details before deleting for activity
    Expense? expense;
    try {
      expense = await getExpense(expenseId);
    } catch (e) {
      // If we can't get expense, still proceed with deletion
    }

    // Splits will be deleted automatically due to CASCADE
    await supabase().from('expenses').delete().eq('id', expenseId);

    // Create activity for expense deleted
    if (expense != null) {
      final activitiesRepo = ActivitiesRepo();
      final currencySymbol = expense.currency == 'INR' ? '₹' : expense.currency;
      await activitiesRepo.createActivity(
        groupId: expense.groupId,
        userId: uid,
        activityType: 'expense_deleted',
        description: '$currencySymbol${expense.amount.toStringAsFixed(2)} - ${expense.title}',
        relatedId: expenseId,
      );
    }
  }
}

