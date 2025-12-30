import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../supabase/supabase_client.dart';

class DataExportService {
  /// Export all user data as JSON
  static Future<void> exportAllData() async {
    try {
      final userId = supabase().auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all user data
      final exportData = <String, dynamic>{
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile': await _fetchProfile(userId),
        'groups': await _fetchGroups(userId),
      };

      // Fetch expenses and budgets for each group
      for (var group in exportData['groups'] as List) {
        final groupId = group['id'] as String;
        group['expenses'] = await _fetchExpenses(groupId);
        group['expense_splits'] = await _fetchExpenseSplits(groupId);
        group['group_budgets'] = await _fetchGroupBudgets(groupId);
        group['user_budgets'] = await _fetchUserBudgets(groupId, userId);
        group['settlements'] = await _fetchSettlements(groupId);
        group['members'] = await _fetchGroupMembers(groupId);
      }

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/trip_expense_export_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MOMENTRA Data Export',
        text: 'My MOMENTRA data export',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final res = await supabase()
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return res as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchGroups(String userId) async {
    try {
      // Get groups where user is a member
      final membersRes = await supabase()
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (membersRes as List)
          .map((e) => e['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      // Use OR conditions for multiple IDs
      final orConditions = groupIds.map((id) => 'id.eq.$id').join(',');
      final groupsRes = await supabase()
          .from('groups')
          .select()
          .or(orConditions);

      return (groupsRes as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchExpenses(String groupId) async {
    try {
      final res = await supabase()
          .from('expenses')
          .select()
          .eq('group_id', groupId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchExpenseSplits(String groupId) async {
    try {
      // Get expense IDs for this group
      final expensesRes = await supabase()
          .from('expenses')
          .select('id')
          .eq('group_id', groupId);

      final expenseIds = (expensesRes as List)
          .map((e) => e['id'] as String)
          .toList();

      if (expenseIds.isEmpty) return [];

      // Use OR conditions for multiple IDs
      final orConditions = expenseIds.map((id) => 'expense_id.eq.$id').join(',');
      final splitsRes = await supabase()
          .from('expense_splits')
          .select()
          .or(orConditions);

      return (splitsRes as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchGroupBudgets(String groupId) async {
    try {
      final res = await supabase()
          .from('group_budgets')
          .select()
          .eq('group_id', groupId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchUserBudgets(String groupId, String userId) async {
    try {
      final res = await supabase()
          .from('user_budgets')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchSettlements(String groupId) async {
    try {
      final res = await supabase()
          .from('settlements')
          .select()
          .eq('group_id', groupId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchGroupMembers(String groupId) async {
    try {
      final res = await supabase()
          .from('group_members')
          .select()
          .eq('group_id', groupId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}

