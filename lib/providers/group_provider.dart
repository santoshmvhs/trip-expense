import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<GroupModel> _groups = [];
  Map<String, List<UserModel>> _groupMembers = {};
  bool _isLoading = false;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  GroupProvider() {
    loadGroups();
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('group_members')
          .select('group_id, groups(*)')
          .eq('user_id', userId);

      _groups = (response as List)
          .map((item) => GroupModel.fromJson(item['groups'] as Map<String, dynamic>))
          .toList();

      // Load members for each group
      for (var group in _groups) {
        await loadGroupMembers(group.id);
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('user_id, profiles(*)')
          .eq('group_id', groupId);

      _groupMembers[groupId] = (response as List)
          .map((item) => UserModel.fromJson(item['profiles'] as Map<String, dynamic>))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  List<UserModel> getGroupMembers(String groupId) {
    return _groupMembers[groupId] ?? [];
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String currency = 'USD',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Ensure profile exists before creating group
      final profileCheck = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId);

      if (profileCheck == null || profileCheck.isEmpty) {
        // Profile doesn't exist, create it (handle duplicate key if trigger already created it)
        final user = _supabase.auth.currentUser;
        if (user != null) {
          try {
            await _supabase.from('profiles').insert({
              'id': user.id,
              'email': user.email ?? '',
              'full_name': user.userMetadata?['full_name'] ?? '',
            });
          } catch (e) {
            // Profile might have been created by trigger, ignore duplicate key error
            if (!e.toString().contains('duplicate key')) {
              rethrow;
            }
          }
        } else {
          throw Exception('User not found');
        }
      }

      final response = await _supabase.from('groups').insert({
        'name': name,
        'description': description,
        'currency': currency,
        'created_by': userId,
      }).select().single();

      final group = GroupModel.fromJson(response);

      // Add creator as member
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
      });

      _groups.add(group);
      await loadGroupMembers(group.id);
      notifyListeners();

      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  Future<String> addMemberToGroup(String groupId, String userEmail) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Normalize email
      final normalizedEmail = userEmail.trim().toLowerCase();

      // First check if user exists
      final userResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', normalizedEmail);

      if (userResponse != null && userResponse.isNotEmpty) {
        // User exists - add directly
        final existingUserId = (userResponse[0] as Map<String, dynamic>)['id'] as String;

        // Check if user is already a member
        final existingMember = await _supabase
            .from('group_members')
            .select()
            .eq('group_id', groupId)
            .eq('user_id', existingUserId);

        if (existingMember != null && existingMember.isNotEmpty) {
          return 'already_member';
        }

        await _supabase.from('group_members').insert({
          'group_id': groupId,
          'user_id': existingUserId,
        });

        await loadGroupMembers(groupId);
        notifyListeners();
        return 'success';
      } else {
        // User doesn't exist - create invitation
        // Check if invitation already exists
        final existingInvitation = await _supabase
            .from('group_invitations')
            .select()
            .eq('group_id', groupId)
            .eq('email', normalizedEmail)
            .eq('status', 'pending');

        if (existingInvitation != null && existingInvitation.isNotEmpty) {
          return 'invitation_exists';
        }

        // Create invitation
        await _supabase.from('group_invitations').insert({
          'group_id': groupId,
          'email': normalizedEmail,
          'invited_by': userId,
          'status': 'pending',
        });

        // Create notification for when they sign up (if we can)
        // For now, the trigger will handle it when they sign up
        
        // TODO: Send email invitation via Supabase Edge Function or email service
        // You can set up a Supabase Edge Function to send emails
        
        return 'invitation_sent';
      }
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _supabase.from('groups').delete().eq('id', groupId);
      _groups.removeWhere((g) => g.id == groupId);
      _groupMembers.remove(groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }
}

