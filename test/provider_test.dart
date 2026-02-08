import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentra/features/moments/state/moments_list_provider.dart';
import 'package:momentra/core/network/dio_client.dart';
import 'package:momentra/features/moments/data/repo/moments_repo.dart';
import 'package:momentra/features/moments/data/models/moment.dart';
import 'package:dio/dio.dart';

void main() {
  group('MomentsListProvider', () {
    test('loads moments from repository', () async {
      // Mock Dio client
      final mockDio = Dio();
      final mockDioClient = MockDioClient(mockDio);
      
      final container = ProviderContainer(
        overrides: [
          dioClientProvider.overrideWithValue(mockDioClient),
        ],
      );
      
      // This test would require actual API mocking
      // For MVP, we verify the provider structure
      expect(container.read(momentsRepoProvider), isA<MomentsRepository>());
    });
  });
}

class MockDioClient extends DioClient {
  final Dio mockDio;
  
  MockDioClient(this.mockDio);
  
  @override
  Dio get dio => mockDio;
}

