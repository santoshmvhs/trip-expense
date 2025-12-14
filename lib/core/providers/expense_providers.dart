import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../repositories/expenses_repo.dart';
import '../supabase/supabase_client.dart';

final expensesRepoProvider = Provider((_) => ExpensesRepo());

final groupExpensesProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(expensesRepoProvider).listGroupExpenses(groupId);
});

final groupMembersProvider = FutureProvider.family((ref, String groupId) async {
  if (groupId.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠️ groupMembersProvider: groupId is empty');
    }
    return <Map<String, dynamic>>[];
  }

  try {
    // Step 1: Get all user IDs from group_members
    final membersRes = await supabase()
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final memberList = (membersRes as List);
    if (memberList.isEmpty) return <Map<String, dynamic>>[];

    final userIds = memberList.map((e) => e['user_id'] as String).toList();
    if (userIds.isEmpty) return <Map<String, dynamic>>[];

    // Step 2: Get all profiles in one query using 'in' filter
    // Build the filter: id=in.(uuid1,uuid2,uuid3)
    final profilesRes = await supabase()
        .from('profiles')
        .select('id, name')
        .in_('id', userIds);

    // Create a map of userId -> name
    final profilesMap = <String, String>{};
    for (final profile in (profilesRes as List)) {
      final id = profile['id'] as String;
      final nameValue = profile['name'];
      
      if (nameValue is String && nameValue.trim().isNotEmpty) {
        profilesMap[id] = nameValue.trim();
      } else {
        profilesMap[id] = 'User ${id.substring(0, 8)}';
      }
    }

    // Step 3: Combine and return with names
    return memberList.map((e) {
      final userId = e['user_id'] as String;
      return {
        'user_id': userId,
        'name': profilesMap[userId] ?? 'User ${userId.substring(0, 8)}',
      };
    }).toList();
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Error in groupMembersProvider for groupId=$groupId: $e');
      debugPrint('   Stack: $stackTrace');
    }
    return <Map<String, dynamic>>[];
  }
});

