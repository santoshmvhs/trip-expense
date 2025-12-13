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

  // Then get profiles for those users
  if (userIds.isEmpty) return <Map<String, dynamic>>[];

  final orConditions = userIds.map((id) => 'id.eq.$id').join(',');
  final profilesRes = await supabase()
      .from('profiles')
      .select('id, name')
      .or(orConditions);

  final profilesMap = <String, String>{};
  for (final profile in (profilesRes as List)) {
    final id = profile['id'] as String;
    final name = (profile['name'] as String?)?.isNotEmpty == true
        ? profile['name'] as String
        : 'Unknown';
    profilesMap[id] = name;
  }

  // Combine and return
  return memberList.map((e) {
    final userId = e['user_id'] as String;
    return {
      'user_id': userId,
      'name': profilesMap[userId] ?? 'Unknown',
    };
  }).toList();
});

