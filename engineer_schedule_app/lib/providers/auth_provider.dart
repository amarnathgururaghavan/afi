import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────────────────

  ProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isAuthenticated => _profile != null;

  bool get isAdmin => _profile?.isAdmin ?? false;

  String get currentUserId => _supabaseService.currentUser?.id ?? '';

  // ── Methods ──────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  /// Returns `true` on success, `false` on failure (error stored in [error]).
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.signIn(email, password);

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _error = 'Authentication succeeded but no user ID was returned.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _profile = await _supabaseService.getProfile(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs out and clears all local state.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _profile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the profile for the currently authenticated user.
  /// No-op if no user session exists.
  Future<void> loadProfile() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _supabaseService.getProfile(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
