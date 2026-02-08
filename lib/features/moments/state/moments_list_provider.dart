import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/repo/moments_repo.dart';
import '../data/models/moment.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final momentsRepoProvider = Provider<MomentsRepository>((ref) {
  return MomentsRepository(ref.watch(dioClientProvider));
});

final momentsListProvider = FutureProvider<List<Moment>>((ref) async {
  final repo = ref.watch(momentsRepoProvider);
  return await repo.getMoments();
});

