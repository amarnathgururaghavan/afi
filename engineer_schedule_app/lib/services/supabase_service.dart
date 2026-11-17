import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/schedule_model.dart';
import '../utils/constants.dart';
import 'schedule_repository.dart';

class SupabaseService implements ScheduleRepository {
  final SupabaseClient _client;

  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign-out failed: $e');
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // PROFILES
  // ---------------------------------------------------------------------------

  Future<ProfileModel> getProfile(String userId) async {
    try {
      final data = await _client
          .from(DbTables.profiles)
          .select()
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      final data = await _client
          .from(DbTables.profiles)
          .select()
          .order('full_name', ascending: true);
      return (data as List).map((json) => ProfileModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch profiles: $e');
    }
  }

  Future<ProfileModel> adminCreateUser({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    try {
      final res = await _client.rpc('admin_create_user', params: {
        'new_email': email,
        'new_password': password,
        'new_full_name': fullName,
        'new_role': role,
      });
      return ProfileModel.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> adminDeleteUser(String userId) async {
    try {
      await _client.rpc('admin_delete_user', params: {
        'target_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<void> adminResetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await _client.rpc('admin_reset_user_password', params: {
        'target_user_id': userId,
        'new_password': newPassword,
      });
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SCHEDULES – READ
  // ---------------------------------------------------------------------------

  @override
  Future<List<ScheduleModel>> getSchedulesForUser(String userId) async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .select()
          .eq('user_id', userId)
          .order('schedule_date', ascending: true);
      return (data as List)
          .map((json) => ScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user schedules: $e');
    }
  }

  @override
  Future<List<ScheduleModel>> getAllSchedules() async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .select()
          .order('schedule_date', ascending: true);
      return (data as List)
          .map((json) => ScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all schedules: $e');
    }
  }

  @override
  Future<List<ScheduleModel>> getSchedulesByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    try {
      final String startStr =
          '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final String endStr =
          '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      var query = _client
          .from(DbTables.schedules)
          .select()
          .gte('schedule_date', startStr)
          .lte('schedule_date', endStr);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final data = await query.order('schedule_date', ascending: true);
      return (data as List)
          .map((json) => ScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules by date range: $e');
    }
  }

  @override
  Future<List<ScheduleModel>> getSchedulesByEngineerName(String name) async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .select()
          .ilike('engineer_name', '%$name%')
          .order('schedule_date', ascending: true);
      return (data as List)
          .map((json) => ScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules by engineer name: $e');
    }
  }

  @override
  Future<List<ScheduleModel>> getSchedulesBySite(String siteName) async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .select()
          .ilike('site_name', '%$siteName%')
          .order('schedule_date', ascending: true);
      return (data as List)
          .map((json) => ScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch schedules by site: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SCHEDULES – CREATE / UPDATE / DELETE
  // ---------------------------------------------------------------------------

  @override
  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .insert(schedule.toInsertJson())
          .select()
          .single();
      return ScheduleModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create schedule: $e');
    }
  }

  @override
  Future<ScheduleModel> updateSchedule(ScheduleModel schedule) async {
    try {
      final data = await _client
          .from(DbTables.schedules)
          .update(schedule.toUpdateJson())
          .eq('id', schedule.id)
          .select()
          .single();
      return ScheduleModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _client
          .from(DbTables.schedules)
          .delete()
          .eq('id', scheduleId);
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }
}
