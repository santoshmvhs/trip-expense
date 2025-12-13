import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/activities_repo.dart';
import '../models/group_activity.dart';

final activitiesRepoProvider = Provider((_) => ActivitiesRepo());

final groupActivitiesProvider = FutureProvider.family((ref, String groupId) {
  return ref.watch(activitiesRepoProvider).getGroupActivities(groupId);
});

final groupActivitiesLimitedProvider = FutureProvider.family((ref, ({String groupId, int limit}) params) {
  return ref.watch(activitiesRepoProvider).getGroupActivities(params.groupId, limit: params.limit);
});

