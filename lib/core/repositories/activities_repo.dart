import '../supabase/supabase_client.dart';
import '../models/group_activity.dart';
import 'package:intl/intl.dart';

class ActivitiesRepo {
  Future<List<GroupActivity>> getGroupActivities(String groupId, {int? limit}) async {
    var query = supabase()
        .from('group_activities')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final res = await query;

    return (res as List)
        .map((e) => GroupActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroupActivity>> getUserActivities(String userId, {int? limit}) async {
    var query = supabase()
        .from('group_activities')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final res = await query;

    return (res as List)
        .map((e) => GroupActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createActivity({
    required String groupId,
    required String userId,
    required String activityType,
    required String description,
    String? relatedId,
  }) async {
    try {
      await supabase().from('group_activities').insert({
        'group_id': groupId,
        'user_id': userId,
        'activity_type': activityType,
        'description': description,
        'related_id': relatedId,
      });
    } catch (e) {
      // Log error but don't fail the operation
      print('Error creating activity: $e');
    }
  }
}

