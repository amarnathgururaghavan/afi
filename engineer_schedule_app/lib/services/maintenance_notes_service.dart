import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maintenance_note_model.dart';
import '../utils/constants.dart';

/// Service handling Supabase CRUD and Realtime subscriptions for Maintenance Notes.
class MaintenanceNotesService {
  final SupabaseClient _client;

  MaintenanceNotesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches maintenance notes, ordered newest first.
  /// If [isAdmin] is false, strictly filters by [userId] so engineers only see their own notes.
  Future<List<MaintenanceNote>> fetchNotes({
    String? siteName,
    String? status,
    String? userId,
    bool isAdmin = true,
  }) async {
    try {
      var query = _client.from(DbTables.maintenanceNotes).select('*');

      // Role boundary: Engineer only sees their own notes
      if (!isAdmin && userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      if (siteName != null && siteName.isNotEmpty && siteName != 'ALL') {
        query = query.ilike('site_name', siteName.trim());
      }

      if (status != null && status.isNotEmpty && status != 'ALL') {
        query = query.eq('status', status.trim());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((row) => MaintenanceNote.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching maintenance notes: $e');
      throw Exception('Failed to fetch maintenance notes: $e');
    }
  }

  /// Inserts a new maintenance note.
  Future<MaintenanceNote> createNote(MaintenanceNote note) async {
    try {
      final response = await _client
          .from(DbTables.maintenanceNotes)
          .insert(note.toInsertJson())
          .select()
          .single();

      return MaintenanceNote.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error creating maintenance note: $e');
      throw Exception('Failed to create maintenance note: $e');
    }
  }

  /// Updates an existing maintenance note.
  Future<MaintenanceNote> updateNote(MaintenanceNote note) async {
    try {
      final response = await _client
          .from(DbTables.maintenanceNotes)
          .update(note.toUpdateJson())
          .eq('id', note.id)
          .select()
          .single();

      return MaintenanceNote.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error updating maintenance note: $e');
      throw Exception('Failed to update maintenance note: $e');
    }
  }

  /// Deletes a maintenance note by its unique UUID.
  Future<void> deleteNote(String id) async {
    try {
      await _client.from(DbTables.maintenanceNotes).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting maintenance note: $e');
      throw Exception('Failed to delete maintenance note: $e');
    }
  }

  /// Subscribes to Postgres changes for realtime synchronization.
  RealtimeChannel subscribeToNotes(void Function() onUpdate) {
    final channel = _client.channel('maintenance-notes-realtime');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: DbTables.maintenanceNotes,
      callback: (payload) {
        onUpdate();
      },
    );
    channel.subscribe();
    return channel;
  }
}
