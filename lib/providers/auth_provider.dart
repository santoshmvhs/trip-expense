import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await loadUser();
    }
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        loadUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUser() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId);

      if (response != null && response.isNotEmpty) {
        _currentUser = UserModel.fromJson(response[0] as Map<String, dynamic>);
        notifyListeners();
      } else {
        // Profile doesn't exist yet, create it
        final user = _supabase.auth.currentUser;
        if (user != null) {
          try {
            await _supabase.from('profiles').insert({
              'id': user.id,
              'email': user.email ?? '',
              'full_name': user.userMetadata?['full_name'] ?? '',
            });
            await loadUser(); // Reload after creating
          } catch (insertError) {
            // Profile might have been created by trigger, ignore duplicate key error
            if (insertError.toString().contains('duplicate key')) {
              // Profile already exists, just reload
              final retryResponse = await _supabase
                  .from('profiles')
                  .select()
                  .eq('id', userId);
              if (retryResponse != null && retryResponse.isNotEmpty) {
                _currentUser = UserModel.fromJson(retryResponse[0] as Map<String, dynamic>);
                notifyListeners();
              }
            } else {
              debugPrint('Error creating profile: $insertError');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        await loadUser();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await loadUser();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(String fullName, String? avatarUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await loadUser();
    } catch (e) {
      rethrow;
    }
  }
}

