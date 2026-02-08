import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';

class DioClient {
  late Dio _dio;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from Supabase session
        final session = _supabase.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          // Sign out user if token is invalid
          _supabase.auth.signOut();
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
}

