import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' show AppUser, AppAuthResponse;
import '../../../../core/supabase/supabase_client.dart';

class AuthRepository {
  final SupabaseClient _supabase = supabase();
  
  Future<AppAuthResponse> register(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (response.user == null) {
        throw Exception('Registration failed: User not created');
      }

      // Create profile if it doesn't exist
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final profileCheck = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle();

        if (profileCheck == null) {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'email': response.user!.email ?? email,
            'full_name': name,
          });
        }
      } catch (e) {
        // Profile might already exist or RLS issue - continue anyway
        debugPrint('Profile creation note: $e');
      }

      return AppAuthResponse(
        user: AppUser(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: name,
        ),
        token: response.session?.accessToken ?? '',
      );
    } on AuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  Future<AppAuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw Exception('Login failed: Invalid credentials');
      }

      // Load user profile
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      final userName = profileResponse?['full_name'] as String? ?? 
                      profileResponse?['name'] as String? ?? 
                      response.user!.userMetadata?['full_name'] as String? ?? 
                      'User';

      return AppAuthResponse(
        user: AppUser(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: userName,
        ),
        token: response.session!.accessToken,
      );
    } on AuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  Future<AppUser> getMe() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final userName = profileResponse?['full_name'] as String? ?? 
                      profileResponse?['name'] as String? ?? 
                      user.userMetadata?['full_name'] as String? ?? 
                      'User';

      return AppUser(
        id: user.id,
        email: user.email ?? '',
        name: userName,
      );
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
