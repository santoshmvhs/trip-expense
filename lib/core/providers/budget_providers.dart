import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/budgets_repo.dart';
import '../models/group_budget.dart';
import '../models/user_budget.dart';
import '../supabase/supabase_client.dart';

final budgetsRepoProvider = Provider((ref) => BudgetsRepo());

final groupBudgetsProvider = FutureProvider.family<List<GroupBudget>, String>((ref, groupId) {
  return ref.watch(budgetsRepoProvider).getGroupBudgets(groupId);
});

final userBudgetsProvider = FutureProvider.family<List<UserBudget>, Map<String, String>>((ref, params) {
  return ref.watch(budgetsRepoProvider).getUserBudgets(params['groupId']!, params['userId']!);
});

final currentUserBudgetsProvider = FutureProvider.family<List<UserBudget>, String>((ref, groupId) async {
  final userId = supabase().auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(budgetsRepoProvider).getUserBudgets(groupId, userId);
});

