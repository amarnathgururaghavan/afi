import '../models/schedule_model.dart';

/// Abstract data repository contract for schedule persistence and retrieval.
///
/// Keeping providers decoupled behind [ScheduleRepository] allows swapping or
/// syncing with another backend (such as a Google Sheets API service) without
/// changing UI or state-management code.
abstract class ScheduleRepository {
  /// Fetches all schedules assigned to a specific [userId].
  Future<List<ScheduleModel>> getSchedulesForUser(String userId);

  /// Fetches all schedules across all engineers (admin access).
  Future<List<ScheduleModel>> getAllSchedules();

  /// Fetches schedules between [start] and [end] inclusive, optionally
  /// scoped to [userId].
  Future<List<ScheduleModel>> getSchedulesByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  });

  /// Fetches schedules matching [name].
  Future<List<ScheduleModel>> getSchedulesByEngineerName(String name);

  /// Fetches schedules matching [siteName].
  Future<List<ScheduleModel>> getSchedulesBySite(String siteName);

  /// Persists a new [schedule] entry and returns the saved record.
  Future<ScheduleModel> createSchedule(ScheduleModel schedule);

  /// Updates an existing [schedule] entry and returns the updated record.
  Future<ScheduleModel> updateSchedule(ScheduleModel schedule);

  /// Deletes the schedule identified by [scheduleId].
  Future<void> deleteSchedule(String scheduleId);
}
