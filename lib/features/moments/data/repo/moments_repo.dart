import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants.dart';
import '../models/moment.dart';
import '../models/moment_detail.dart';
import '../models/participant.dart';
import '../models/contribution.dart';

class MomentsRepository {
  final DioClient _dioClient;
  
  MomentsRepository(this._dioClient);
  
  Future<List<Moment>> getMoments() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.moments());
      final List<dynamic> data = response.data;
      return data.map((json) => Moment.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load moments: ${e.message}');
    }
  }
  
  Future<MomentDetail> getMomentDetail(String momentId) async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.moment(momentId));
      return MomentDetail.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load moment: ${e.message}');
    }
  }
  
  Future<Moment> createMoment(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.moments(),
        data: data,
      );
      return Moment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create moment: ${e.message}');
    }
  }
  
  Future<Moment> updateMoment(String momentId, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiEndpoints.moment(momentId),
        data: data,
      );
      return Moment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update moment: ${e.message}');
    }
  }
  
  Future<Moment> closeMoment(String momentId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.closeMoment(momentId),
      );
      return Moment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to close moment: ${e.message}');
    }
  }
  
  Future<List<Participant>> getParticipants(String momentId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.participants(momentId),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Participant.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load participants: ${e.message}');
    }
  }
  
  Future<Participant> addParticipant(
    String momentId,
    String email,
    String? displayName,
    String role,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.participants(momentId),
        data: {
          'email': email,
          'displayName': displayName,
          'role': role,
        },
      );
      return Participant.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add participant: ${e.message}');
    }
  }
  
  Future<List<Contribution>> getContributions(String momentId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.contributions(momentId),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Contribution.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load contributions: ${e.message}');
    }
  }
  
  Future<Contribution> addContribution(
    String momentId,
    double amount,
    String? note,
    String? participantEmail,
    String? participantId,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.contributions(momentId),
        data: {
          'amount': amount,
          'note': note,
          if (participantEmail != null) 'participantEmail': participantEmail,
          if (participantId != null) 'participantId': participantId,
        },
      );
      return Contribution.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add contribution: ${e.message}');
    }
  }
  
  Future<Map<String, dynamic>> getMomentSummary(String momentId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.momentSummary(momentId),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to load summary: ${e.message}');
    }
  }
}

