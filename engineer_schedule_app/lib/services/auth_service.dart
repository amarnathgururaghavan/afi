import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabaseService;

  AuthService(this._supabaseService);

  /// Signs in with email/password, then fetches and returns the user's profile.
  Future<ProfileModel> signIn(String email, String password) async {
    try {
      final authResponse = await _supabaseService.signIn(email, password);
      final user = authResponse.user;
      if (user == null) {
        throw Exception('Authentication succeeded but no user was returned.');
      }
      final profile = await _supabaseService.getProfile(user.id);
      return profile;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _supabaseService.signOut();
  }

  /// Whether a user session currently exists.
  bool get isAuthenticated => _supabaseService.currentUser != null;

  /// The currently authenticated Supabase user, or null.
  User? get currentUser => _supabaseService.currentUser;
}
