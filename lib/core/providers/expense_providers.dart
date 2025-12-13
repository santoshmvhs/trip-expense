import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/expenses_repo.dart';
import '../supabase/supabase_client.dart';

final expensesRepoProvider = Provider((_) => ExpensesRepo());

final groupExpensesProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(expensesRepoProvider).listGroupExpenses(groupId);
});

final groupMembersProvider = FutureProvider.family((ref, String groupId) async {
  // First get group members
  final membersRes = await supabase()
      .from('group_members')
      .select('user_id')
      .eq('group_id', groupId);

  final memberList = (membersRes as List);
  if (memberList.isEmpty) return <Map<String, dynamic>>[];

  // Get user IDs
  final userIds = memberList.map((e) => e['user_id'] as String).toList();
  if (userIds.isEmpty) return <Map<String, dynamic>>[];

  // Query all profiles at once using .or() with proper syntax
  // Build OR conditions: id.eq.uuid1,id.eq.uuid2,...
  final orConditions = userIds.map((id) => 'id.eq.$id').join(',');
  
  final profilesRes = await supabase()
      .from('profiles')
      .select('id, name')
      .or(orConditions);

  final profilesMap = <String, String>{};
  for (final profile in (profilesRes as List)) {
    final id = profile['id'] as String;
    final name = profile['name'] as String?;
    
    // Use name if it exists and is not empty
    if (name != null && name.trim().isNotEmpty) {
      profilesMap[id] = name.trim();
    } else {
      // Name is null or empty, create a readable fallback
      profilesMap[id] = 'User ${id.substring(0, 8)}';
    }
  }

  // Combine and return - ensure all members have a name
  // If a profile wasn't found, create a fallback name
  return memberList.map((e) {
    final userId = e['user_id'] as String;
    final name = profilesMap[userId];
    
    return {
      'user_id': userId,
      'name': name ?? 'User ${userId.substring(0, 8)}',
    };
  }).toList();
});

