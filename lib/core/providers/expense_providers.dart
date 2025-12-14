import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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

  // Query profiles individually - most reliable approach
  final profilesMap = <String, String>{};
  
  for (final userId in userIds) {
    try {
      final profileRes = await supabase()
          .from('profiles')
          .select('id, name')
          .eq('id', userId)
          .maybeSingle();
      
      if (kDebugMode) {
        debugPrint('🔍 Querying profile for userId: ${userId.substring(0, 8)}...');
        debugPrint('   Result: ${profileRes != null ? "Found" : "Not found"}');
        if (profileRes != null) {
          debugPrint('   Raw name value: ${profileRes['name']} (type: ${profileRes['name'].runtimeType})');
        }
      }
      
      if (profileRes != null) {
        final nameValue = profileRes['name'];
        
        // Handle different possible types and null cases
        String? name;
        if (nameValue is String) {
          name = nameValue.trim().isEmpty ? null : nameValue.trim();
        } else if (nameValue != null) {
          // Try to convert to string
          name = nameValue.toString().trim().isEmpty ? null : nameValue.toString().trim();
        }
        
        if (name != null && name.isNotEmpty) {
          profilesMap[userId] = name;
          if (kDebugMode) {
            debugPrint('✅ Profile $userId: Using name "$name"');
          }
        } else {
          profilesMap[userId] = 'User ${userId.substring(0, 8)}';
          if (kDebugMode) {
            debugPrint('⚠️ Profile $userId: Name is null/empty, using fallback');
          }
        }
      } else {
        profilesMap[userId] = 'User ${userId.substring(0, 8)}';
        if (kDebugMode) {
          debugPrint('❌ Profile $userId: Profile not found in database');
        }
      }
    } catch (e, stackTrace) {
      profilesMap[userId] = 'User ${userId.substring(0, 8)}';
      if (kDebugMode) {
        debugPrint('❌ Error fetching profile for $userId: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }
  }
  
  if (kDebugMode) {
    debugPrint('📋 Final profilesMap: $profilesMap');
  }

  // Combine and return - ensure all members have a name
  return memberList.map((e) {
    final userId = e['user_id'] as String;
    return {
      'user_id': userId,
      'name': profilesMap[userId] ?? 'User ${userId.substring(0, 8)}',
    };
  }).toList();
});

