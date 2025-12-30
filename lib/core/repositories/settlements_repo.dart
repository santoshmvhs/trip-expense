import '../supabase/supabase_client.dart';
import '../models/settlement.dart';
import '../supabase/supabase_client.dart' show currentUser;

class SettlementsRepo {
  /// Record a payment/settlement between two users
  Future<Settlement> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? method,
    String? notes,
  }) async {
    final inserted = await supabase()
        .from('settlements')
        .insert({
          'group_id': groupId,
          'from_user': fromUserId,
          'to_user': toUserId,
          'amount': amount,
          'currency': currency,
          if (method != null && method.isNotEmpty) 'method': method,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        })
        .select()
        .single();

    return Settlement.fromJson(inserted as Map<String, dynamic>);
  }

  /// Get all settlements for a group
  Future<List<Settlement>> listGroupSettlements(String groupId) async {
    final res = await supabase()
        .from('settlements')
        .select()
        .eq('group_id', groupId)
        .order('settled_at', ascending: false);

    return (res as List)
        .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Delete a settlement
  Future<void> deleteSettlement(String settlementId) async {
    await supabase().from('settlements').delete().eq('id', settlementId);
  }
}

