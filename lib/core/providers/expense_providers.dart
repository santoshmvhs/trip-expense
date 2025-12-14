import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../repositories/expenses_repo.dart';
import '../supabase/supabase_client.dart';

final expensesRepoProvider = Provider((_) => ExpensesRepo());

final groupExpensesProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(expensesRepoProvider).listGroupExpenses(groupId);
});

final groupMembersProvider = FutureProvider.family((ref, String groupId) async {
  // Auto-refresh to ensure we get latest data
  ref.keepAlive();
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

  // Query all profiles at once using filter with 'in' operator
  final profilesMap = <String, String>{};
  
  try {
    // Build filter query for all user IDs
    var query = supabase()
        .from('profiles')
        .select('id, name');
    
    // Add filter conditions for each user ID
    for (int i = 0; i < userIds.length; i++) {
      if (i == 0) {
        query = query.eq('id', userIds[i]);
      } else {
        query = query.or('id.eq.${userIds[i]}');
      }
    }
    
    final profilesRes = await query;
    
    if (kDebugMode) {
      debugPrint('🔍 Fetched ${(profilesRes as List).length} profiles for ${userIds.length} user IDs');
    }
    
    // Build map from results
    for (final profile in (profilesRes as List)) {
      final id = profile['id'] as String;
      final name = profile['name'];
      
      if (name is String && name.trim().isNotEmpty) {
        profilesMap[id] = name.trim();
        if (kDebugMode) {
          debugPrint('✅ Profile $id: ${name.trim()}');
        }
      } else {
        profilesMap[id] = 'User ${id.substring(0, 8)}';
        if (kDebugMode) {
          debugPrint('⚠️ Profile $id: name is null/empty, using fallback');
        }
      }
    }
    
    // Fill in fallbacks for any missing profiles
    for (final userId in userIds) {
      if (!profilesMap.containsKey(userId)) {
        profilesMap[userId] = 'User ${userId.substring(0, 8)}';
        if (kDebugMode) {
          debugPrint('❌ Profile $userId: not found in query results, using fallback');
        }
      }
    }
  } catch (e, stackTrace) {
    // If batch query fails, fall back to individual queries
    if (kDebugMode) {
      debugPrint('❌ Batch query failed, trying individual queries: $e');
    }
    
    for (final userId in userIds) {
      try {
        final profileRes = await supabase()
            .from('profiles')
            .select('id, name')
            .eq('id', userId)
            .maybeSingle();
        
        if (profileRes != null) {
          final name = profileRes['name'];
          if (name is String && name.trim().isNotEmpty) {
            profilesMap[userId] = name.trim();
          } else {
            profilesMap[userId] = 'User ${userId.substring(0, 8)}';
          }
        } else {
          profilesMap[userId] = 'User ${userId.substring(0, 8)}';
        }
      } catch (e2) {
        profilesMap[userId] = 'User ${userId.substring(0, 8)}';
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

