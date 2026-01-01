import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../supabase/supabase_client.dart';
import '../models/moment.dart';
import '../models/moment_participant.dart';
import '../models/moment_contribution.dart';
import '../models/moment_health.dart';
import '../models/moment_guidance.dart';
import '../models/moment_wishlist_item.dart';

class MomentsRepo {
  /// List moments for a user (all moments they created or are participants in)
  Future<List<Moment>> listMyMoments({String? groupId}) async {
    try {
      final queryBuilder = supabase()
          .from('moments')
          .select('*');
      
      if (groupId != null) {
        final res = await queryBuilder
            .eq('group_id', groupId)
            .order('updated_at', ascending: false);
        return (res as List)
            .map((e) => Moment.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final res = await queryBuilder
            .order('updated_at', ascending: false);
        return (res as List)
            .map((e) => Moment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      developer.log('Error listing moments: $e');
      rethrow;
    }
  }

  /// Get a single moment by ID
  Future<Moment> getMoment(String momentId) async {
    final res = await supabase()
        .from('moments')
        .select('*')
        .eq('id', momentId)
        .single();

    return Moment.fromJson(res as Map<String, dynamic>);
  }

  /// Create a new moment
  Future<Moment> createMoment({
    String? groupId,
    required String type,
    required String title,
    String? description,
    required double targetAmount,
    DateTime? startDate, // NULLABLE: defaults to NOW() in database
    required DateTime endDate,
  }) async {
    final uid = currentUser()!.id;
    
    final inserted = await supabase()
        .from('moments')
        .insert({
          'group_id': groupId,
          'type': type,
          'title': title,
          'description': description,
          'target_amount': targetAmount,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'created_by': uid,
        })
        .select('*')
        .single();

    // Auto-add creator as participant with 'creator' role
    try {
      final userEmail = currentUser()!.email ?? '';
      await supabase().from('moment_participants').insert({
        'moment_id': inserted['id'],
        'user_id': uid,
        'email': userEmail,
        'role': 'creator',
      });
    } catch (e) {
      developer.log('Note: Could not auto-add creator as participant: $e');
    }

    return Moment.fromJson(inserted as Map<String, dynamic>);
  }

  /// Update a moment
  Future<Moment> updateMoment(String momentId, Map<String, dynamic> updates) async {
    final res = await supabase()
        .from('moments')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', momentId)
        .select('*')
        .single();

    return Moment.fromJson(res as Map<String, dynamic>);
  }

  /// Close a moment (set lifecycle_state to COMPLETED)
  Future<Moment> closeMoment(String momentId) async {
    return updateMoment(momentId, {'lifecycle_state': 'COMPLETED'});
  }

  /// Delete a moment
  Future<void> deleteMoment(String momentId) async {
    await supabase()
        .from('moments')
        .delete()
        .eq('id', momentId);
  }

  /// Get participants for a moment
  Future<List<MomentParticipant>> getParticipants(String momentId) async {
    final res = await supabase()
        .from('moment_participants')
        .select('*')
        .eq('moment_id', momentId)
        .order('joined_at', ascending: true);

    return (res as List)
        .map((e) => MomentParticipant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a participant to a moment
  Future<MomentParticipant> addParticipant({
    required String momentId,
    String? userId,
    required String email,
    String? displayName,
    String role = 'contributor',
  }) async {
    final inserted = await supabase()
        .from('moment_participants')
        .insert({
          'moment_id': momentId,
          'user_id': userId,
          'email': email,
          'display_name': displayName,
          'role': role,
        })
        .select('*')
        .single();

    return MomentParticipant.fromJson(inserted as Map<String, dynamic>);
  }

  /// Get contributions for a moment
  Future<List<MomentContribution>> getContributions(String momentId) async {
    final res = await supabase()
        .from('moment_contributions')
        .select('*')
        .eq('moment_id', momentId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => MomentContribution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a contribution to a moment
  Future<MomentContribution> addContribution({
    required String momentId,
    required String participantId,
    required double amount,
    String? note,
    String? expenseId, // Link to expense if applicable
  }) async {
    final inserted = await supabase()
        .from('moment_contributions')
        .insert({
          'moment_id': momentId,
          'participant_id': participantId,
          'amount': amount,
          'note': note,
          'expense_id': expenseId,
        })
        .select('*')
        .single();

    return MomentContribution.fromJson(inserted as Map<String, dynamic>);
  }

  /// Calculate moment health (client-side calculation matching backend logic)
  Future<MomentHealth> calculateHealth(Moment moment) async {
    final now = DateTime.now();
    final startDate = moment.startDate ?? moment.createdAt;
    final endDate = moment.endDate;
    
    // Calculate time elapsed ratio
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    final timeElapsedRatio = totalDuration > 0 
        ? (elapsedDuration / totalDuration).clamp(0.0, 1.0)
        : 0.0;
    
    // Calculate funding ratio
    final fundingRatio = moment.targetAmount > 0
        ? (moment.currentAmount / moment.targetAmount).clamp(0.0, double.infinity)
        : 0.0;
    
    // Calculate gap
    final expectedFundingRatio = timeElapsedRatio;
    final gap = expectedFundingRatio - fundingRatio;
    
    // Determine status
    String status;
    String label;
    
    if (fundingRatio >= 1.0) {
      status = 'green';
      label = 'funded';
    } else if (now.isAfter(endDate) && fundingRatio < 1.0) {
      status = 'red';
      label = 'overdue';
    } else if (gap <= 0.10) {
      status = 'green';
      label = 'on-track';
    } else if (gap <= 0.25) {
      status = 'yellow';
      label = 'at-risk';
    } else {
      status = 'red';
      label = 'critical';
    }
    
    return MomentHealth(
      status: status,
      label: label,
      gap: gap,
      fundingRatio: fundingRatio,
      expectedFundingRatio: expectedFundingRatio,
    );
  }

  /// Generate guidance nudges (client-side, matching backend logic)
  Future<MomentGuidance> generateGuidance(Moment moment, MomentHealth health) async {
    final nudges = <MomentGuidanceNudge>[];
    
    // Health-based nudges
    if (health.status == 'yellow') {
      nudges.add(MomentGuidanceNudge(
        message: "You're behind schedule—consider nudging contributors or adjusting target.",
        priority: 'medium',
      ));
    } else if (health.status == 'red') {
      if (health.label == 'overdue') {
        nudges.add(MomentGuidanceNudge(
          message: "Moment ended but target not met—close moment or extend end date.",
          priority: 'high',
        ));
      } else {
        nudges.add(MomentGuidanceNudge(
          message: "Moment is critical—ask top 2 inactive participants to contribute or reduce scope.",
          priority: 'high',
        ));
      }
    } else if (health.status == 'green' && health.label == 'funded') {
      nudges.add(MomentGuidanceNudge(
        message: "Target achieved—consider closing the moment and reviewing contributions.",
        priority: 'low',
      ));
    }
    
    // Description nudge
    if (moment.description == null || moment.description!.isEmpty) {
      nudges.add(MomentGuidanceNudge(
        message: "Add a note with purpose to help participants understand the goal.",
        priority: 'low',
      ));
    }
    
    // Limit to 3 nudges
    return MomentGuidance(nudges: nudges.take(3).toList());
  }

  /// Get wishlist items for a moment
  Future<List<MomentWishlistItem>> getWishlistItems(String momentId) async {
    final res = await supabase()
        .from('moment_wishlist_items')
        .select('*')
        .eq('moment_id', momentId)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => MomentWishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a wishlist item to a moment
  Future<MomentWishlistItem> addWishlistItem({
    required String momentId,
    required String name,
    String? description,
    double? price,
    String? link,
    String priority = 'medium',
    String? imageUrl,
    int quantity = 1,
  }) async {
    final uid = currentUser()!.id;
    
    final inserted = await supabase()
        .from('moment_wishlist_items')
        .insert({
          'moment_id': momentId,
          'name': name,
          'description': description,
          'price': price,
          'link': link,
          'priority': priority,
          'image_url': imageUrl,
          'quantity': quantity,
          'created_by': uid,
        })
        .select('*')
        .single();

    return MomentWishlistItem.fromJson(inserted as Map<String, dynamic>);
  }

  /// Update a wishlist item
  Future<MomentWishlistItem> updateWishlistItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    final res = await supabase()
        .from('moment_wishlist_items')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId)
        .select('*')
        .single();

    return MomentWishlistItem.fromJson(res as Map<String, dynamic>);
  }

  /// Mark a wishlist item as purchased
  Future<MomentWishlistItem> markWishlistItemPurchased({
    required String itemId,
    String? contributionId,
  }) async {
    final uid = currentUser()!.id;
    
    return updateWishlistItem(itemId, {
      'status': 'purchased',
      'purchased_by': uid,
      'purchased_at': DateTime.now().toIso8601String(),
      'contribution_id': contributionId,
    });
  }

  /// Mark a wishlist item as fulfilled
  Future<MomentWishlistItem> markWishlistItemFulfilled(String itemId) async {
    return updateWishlistItem(itemId, {
      'status': 'fulfilled',
    });
  }

  /// Delete a wishlist item
  Future<void> deleteWishlistItem(String itemId) async {
    await supabase()
        .from('moment_wishlist_items')
        .delete()
        .eq('id', itemId);
  }
}

