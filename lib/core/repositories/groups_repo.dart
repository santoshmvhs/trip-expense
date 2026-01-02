import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../supabase/supabase_client.dart';
import '../models/group.dart';

class GroupsRepo {
  Future<List<Group>> listMyGroups() async {
    final userId = currentUser()?.id;
    if (userId == null) {
      debugPrint('⚠️ No user ID, returning empty groups list');
      return [];
    }

    try {
      // Get groups where user is a member
      final res = await supabase()
          .from('group_members')
          .select('group_id, groups(id, name, currency, created_by)')
          .eq('user_id', userId);

      debugPrint('📦 Found ${(res as List).length} group memberships');
      
      final groups = <Group>[];
      for (final item in (res as List)) {
        final groupData = item['groups'];
        if (groupData != null) {
          groups.add(Group.fromJson(groupData as Map<String, dynamic>));
        }
      }

      debugPrint('✅ Loaded ${groups.length} groups');
      return groups;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading groups: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Group> getGroup(String groupId) async {
    final res = await supabase()
        .from('groups')
        .select('id,name,currency,created_by')
        .eq('id', groupId)
        .single();

    return Group.fromJson(res as Map<String, dynamic>);
  }

  Future<Group> createGroup({required String name, String currency = 'INR'}) async {
    final uid = currentUser()!.id;

    final inserted = await supabase()
        .from('groups')
        .insert({'name': name, 'currency': currency, 'created_by': uid})
        .select('id,name,currency,created_by')
        .single();

    // Add creator as admin member
    try {
      await supabase().from('group_members').insert({
        'group_id': inserted['id'],
        'user_id': uid,
        'role': 'admin',
      });
      debugPrint('✅ Group creator added as admin member');
    } catch (e) {
      debugPrint('❌ Error adding creator as member: $e');
      // If RLS fails, try again or throw
      throw Exception('Failed to add creator as group member. Please check RLS policies.');
    }

    return Group.fromJson(inserted as Map<String, dynamic>);
  }

  Future<Group> updateGroup({
    required String groupId,
    required String name,
    String? currency,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
    };
    if (currency != null) {
      updateData['currency'] = currency;
    }

    final updated = await supabase()
        .from('groups')
        .update(updateData)
        .eq('id', groupId)
        .select('id,name,currency,created_by')
        .single();

    return Group.fromJson(updated as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String groupId) async {
    await supabase().from('groups').delete().eq('id', groupId);
  }

  Future<String> addMemberToGroup(String groupId, String userEmail) async {
    debugPrint('🚀 addMemberToGroup called: groupId=$groupId, email=$userEmail');
    developer.log('🚀 addMemberToGroup called: groupId=$groupId, email=$userEmail');
    
    final uid = currentUser()!.id;
    debugPrint('👤 Current user ID: $uid');
    final normalizedEmail = userEmail.trim().toLowerCase();
    debugPrint('📧 Normalized email: $normalizedEmail');

    try {
      // Note: profiles table doesn't have email column, so we can't query users by email
      // We'll create an invitation - users can accept via QR code or share link
      debugPrint('📧 Creating invitation for email: $normalizedEmail');
      developer.log('📧 Creating invitation for email: $normalizedEmail');
        // Check if invitation already exists
        debugPrint('🔍 Checking for existing invitation...');
        final existingInvitation = await supabase()
            .from('group_invitations')
            .select()
            .eq('group_id', groupId)
            .eq('email', normalizedEmail)
            .eq('status', 'pending')
            .maybeSingle();
        
        debugPrint('🔍 Existing invitation check: ${existingInvitation != null ? "Found" : "Not found"}');

        String? token;
        bool isNewInvitation = false;
        
        debugPrint('📋 Processing invitation - existing: ${existingInvitation != null}');
        
        if (existingInvitation != null) {
          debugPrint('⚠️ Invitation already exists - will resend email');
          developer.log('⚠️ Invitation already exists - will resend email');
          token = existingInvitation['token'] as String?;
          debugPrint('🔑 Got token from existing invitation: ${token?.substring(0, 8)}...');
        } else {
          // Create invitation
          debugPrint('📝 Creating new invitation...');
          developer.log('📝 Creating new invitation...');
          
          // Generate a unique token
          final random = Random();
          final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
          final tokenString = tokenBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          final generatedToken = '${DateTime.now().millisecondsSinceEpoch}_$tokenString';
          
          // Set expiration to 30 days from now
          final expiresAt = DateTime.now().add(const Duration(days: 30));
          
          final invitationResponse = await supabase()
              .from('group_invitations')
              .insert({
                'group_id': groupId,
                'email': normalizedEmail,
                'invited_by': uid,
                'status': 'pending',
                'token': generatedToken,
                'expires_at': expiresAt.toIso8601String(),
              })
              .select('token')
              .single();
          
          debugPrint('✅ Invitation insert successful');
          token = invitationResponse['token'] as String?;
          developer.log('✅ Invitation created with token: ${token?.substring(0, 8)}...');
          isNewInvitation = true;
        }

        // Try to send email via Edge Function (optional - won't fail if not configured)
        debugPrint('📨 Attempting to send email...');
        developer.log('📨 Attempting to send email...');
        try {
          // Check if user is logged in
          final currentUser = supabase().auth.currentUser;
          if (currentUser == null) {
            debugPrint('⚠️ User not logged in - skipping email send');
            developer.log('⚠️ User not logged in - skipping email send');
            return isNewInvitation ? 'invitation_sent' : 'invitation_exists';
          }
          
          debugPrint('✅ User logged in: ${currentUser.email}');
          developer.log('✅ User logged in: ${currentUser.email}');
          final group = await getGroup(groupId);
          debugPrint('📧 Calling smart-endpoint function for email: $normalizedEmail');
          debugPrint('📦 Payload: email=$normalizedEmail, groupName=${group.name}, groupId=$groupId');
          developer.log('📧 Calling smart-endpoint function for email: $normalizedEmail');
          developer.log('📦 Payload: email=$normalizedEmail, groupName=${group.name}, groupId=$groupId');
          
          debugPrint('📞 Invoking function: smart-endpoint');
          
          final response = await supabase().functions.invoke(
            'smart-endpoint',
            body: {
              'email': normalizedEmail,
              'groupName': group.name,
              'groupId': groupId,
              'token': token ?? '',
            },
          );
          
          debugPrint('✅ Function call completed');
          debugPrint('✅ Email function response: ${response.data}');
          developer.log('✅ Email function response: ${response.data}');
          debugPrint('✅ Email sent successfully to: $normalizedEmail');
          developer.log('✅ Email sent successfully to: $normalizedEmail');
        } catch (e, stackTrace) {
          // Email sending failed, but invitation is still saved
          // This is okay - invitation will work when user signs up
          debugPrint('❌ Email sending failed (invitation still saved)');
          debugPrint('❌ Error type: ${e.runtimeType}');
          debugPrint('❌ Error message: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          developer.log('❌ Email sending failed (invitation still saved)');
          developer.log('❌ Error type: ${e.runtimeType}');
          developer.log('❌ Error message: $e');
          developer.log('❌ Stack trace: $stackTrace');
          
          // Detailed error analysis
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('function not found') || errorString.contains('404')) {
            developer.log('⚠️ Function smart-endpoint not found. Check Supabase Dashboard.');
            developer.log('⚠️ Make sure function is deployed and named exactly: smart-endpoint');
          } else if (errorString.contains('401') || errorString.contains('jwt') || errorString.contains('unauthorized')) {
            developer.log('⚠️ Authentication error (401).');
            developer.log('⚠️ User might not be logged in or JWT verification is enabled.');
            developer.log('⚠️ Solution: Disable JWT verification in function settings.');
          } else if (errorString.contains('network') || errorString.contains('connection')) {
            developer.log('⚠️ Network error. Check internet connection.');
          } else if (errorString.contains('timeout')) {
            developer.log('⚠️ Request timeout. Function might be slow or not responding.');
          } else {
            developer.log('⚠️ Unknown error. Check Supabase Dashboard function logs.');
          }
        }

        return isNewInvitation ? 'invitation_sent' : 'invitation_exists';
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR in addMemberToGroup: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      developer.log('❌ ERROR in addMemberToGroup: $e');
      developer.log('❌ Stack trace: $stackTrace');
      // If profiles.email doesn't exist, fall back to invitation
      debugPrint('🔄 Falling back to invitation creation...');
      try {
        debugPrint('🔍 Checking for existing invitation (fallback)...');
        final existingInvitation = await supabase()
            .from('group_invitations')
            .select()
            .eq('group_id', groupId)
            .eq('email', normalizedEmail)
            .eq('status', 'pending')
            .maybeSingle();

        if (existingInvitation != null) {
          debugPrint('⚠️ Invitation already exists (fallback)');
          return 'invitation_exists';
        }

        debugPrint('📝 Creating invitation (fallback)...');
        
        // Generate a unique token
        final random = Random();
        final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
        final tokenString = tokenBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        final generatedToken = '${DateTime.now().millisecondsSinceEpoch}_$tokenString';
        
        // Set expiration to 30 days from now
        final expiresAt = DateTime.now().add(const Duration(days: 30));
        
        await supabase().from('group_invitations').insert({
          'group_id': groupId,
          'email': normalizedEmail,
          'invited_by': uid,
          'status': 'pending',
          'token': generatedToken,
          'expires_at': expiresAt.toIso8601String(),
        });

        debugPrint('✅ Invitation created (fallback)');
        return 'invitation_sent';
      } catch (inviteError, stackTrace2) {
        debugPrint('❌ ERROR in fallback: $inviteError');
        debugPrint('❌ Fallback stack trace: $stackTrace2');
        throw Exception('Error inviting member: ${inviteError.toString()}');
      }
    }
  }

  /// Leave a group (only for non-admin members)
  /// Returns true if successful, throws exception if user is admin or not a member
  Future<void> leaveGroup(String groupId) async {
    final uid = currentUser()!.id;
    
    // Check if user is a member and get their role
    final memberRes = await supabase()
        .from('group_members')
        .select('role')
        .eq('group_id', groupId)
        .eq('user_id', uid)
        .maybeSingle();
    
    if (memberRes == null) {
      throw Exception('You are not a member of this group');
    }
    
    final role = memberRes['role'] as String?;
    if (role == 'admin') {
      throw Exception('Admins cannot leave groups. Please transfer admin role or delete the group instead.');
    }
    
    // Delete the member record (RLS policy will verify they're not an admin)
    await supabase()
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', uid);
  }
}

