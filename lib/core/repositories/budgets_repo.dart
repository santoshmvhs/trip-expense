import '../supabase/supabase_client.dart';
import '../models/group_budget.dart';
import '../models/user_budget.dart';

class BudgetsRepo {
  // Group Budgets
  Future<List<GroupBudget>> getGroupBudgets(String groupId) async {
    final response = await supabase()
        .from('group_budgets')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GroupBudget.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<GroupBudget> createGroupBudget({
    required String groupId,
    required String createdBy,
    required double amount,
    required String currency,
    String? category,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{
      'group_id': groupId,
      'created_by': createdBy,
      'amount': amount,
      'currency': currency,
    };

    if (category != null) data['category'] = category;
    if (description != null) data['description'] = description;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await supabase()
        .from('group_budgets')
        .insert(data)
        .select()
        .single();

    return GroupBudget.fromJson(response as Map<String, dynamic>);
  }

  Future<GroupBudget> updateGroupBudget({
    required String budgetId,
    double? amount,
    String? currency,
    String? category,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};

    if (amount != null) data['amount'] = amount;
    if (currency != null) data['currency'] = currency;
    if (category != null) data['category'] = category;
    if (description != null) data['description'] = description;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await supabase()
        .from('group_budgets')
        .update(data)
        .eq('id', budgetId)
        .select()
        .single();

    return GroupBudget.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteGroupBudget(String budgetId) async {
    await supabase().from('group_budgets').delete().eq('id', budgetId);
  }

  // User Budgets
  Future<List<UserBudget>> getUserBudgets(String groupId, String userId) async {
    final response = await supabase()
        .from('user_budgets')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => UserBudget.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserBudget> createUserBudget({
    required String groupId,
    required String userId,
    required double amount,
    required String currency,
    String? category,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{
      'group_id': groupId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
    };

    if (category != null) data['category'] = category;
    if (description != null) data['description'] = description;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await supabase()
        .from('user_budgets')
        .insert(data)
        .select()
        .single();

    return UserBudget.fromJson(response as Map<String, dynamic>);
  }

  Future<UserBudget> updateUserBudget({
    required String budgetId,
    double? amount,
    String? currency,
    String? category,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{};

    if (amount != null) data['amount'] = amount;
    if (currency != null) data['currency'] = currency;
    if (category != null) data['category'] = category;
    if (description != null) data['description'] = description;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];
    data['updated_at'] = DateTime.now().toIso8601String();

    final response = await supabase()
        .from('user_budgets')
        .update(data)
        .eq('id', budgetId)
        .select()
        .single();

    return UserBudget.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteUserBudget(String budgetId) async {
    await supabase().from('user_budgets').delete().eq('id', budgetId);
  }
}

