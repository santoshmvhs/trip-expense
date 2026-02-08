import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/moment_detail.dart';
import 'moments_list_provider.dart';

final momentDetailProvider = FutureProvider.family<MomentDetail, String>((ref, momentId) async {
  final repo = ref.watch(momentsRepoProvider);
  return await repo.getMomentDetail(momentId);
});

