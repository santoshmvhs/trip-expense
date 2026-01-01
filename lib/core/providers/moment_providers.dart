import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/moments_repo.dart';
import '../models/moment.dart';
import '../models/moment_participant.dart';
import '../models/moment_contribution.dart';
import '../models/moment_health.dart';
import '../models/moment_guidance.dart';
import '../models/moment_wishlist_item.dart';

final momentsRepoProvider = Provider<MomentsRepo>((ref) => MomentsRepo());

/// Provider for listing moments (optionally filtered by group)
final momentsProvider = FutureProvider.family<List<Moment>, String?>((ref, groupId) {
  return ref.watch(momentsRepoProvider).listMyMoments(groupId: groupId);
});

/// Provider for a single moment
final momentProvider = FutureProvider.family<Moment, String>((ref, momentId) {
  return ref.watch(momentsRepoProvider).getMoment(momentId);
});

/// Provider for moment participants
final momentParticipantsProvider = FutureProvider.family<List<MomentParticipant>, String>((ref, momentId) {
  return ref.watch(momentsRepoProvider).getParticipants(momentId);
});

/// Provider for moment contributions
final momentContributionsProvider = FutureProvider.family<List<MomentContribution>, String>((ref, momentId) {
  return ref.watch(momentsRepoProvider).getContributions(momentId);
});

/// Provider for moment health (computed)
final momentHealthProvider = FutureProvider.family<MomentHealth, String>((ref, momentId) async {
  final moment = await ref.watch(momentProvider(momentId).future);
  return ref.watch(momentsRepoProvider).calculateHealth(moment);
});

/// Provider for moment guidance (computed)
final momentGuidanceProvider = FutureProvider.family<MomentGuidance, String>((ref, momentId) async {
  final moment = await ref.watch(momentProvider(momentId).future);
  final health = await ref.watch(momentHealthProvider(momentId).future);
  return ref.watch(momentsRepoProvider).generateGuidance(moment, health);
});

/// Provider for moment wishlist items
final momentWishlistItemsProvider = FutureProvider.family<List<MomentWishlistItem>, String>((ref, momentId) {
  return ref.watch(momentsRepoProvider).getWishlistItems(momentId);
});

