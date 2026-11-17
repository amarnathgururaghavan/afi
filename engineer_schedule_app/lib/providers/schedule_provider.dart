import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_repository.dart';
import '../services/supabase_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repository;

  ScheduleProvider({ScheduleRepository? repository})
      : _repository = repository ?? SupabaseService();

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _error;
  String? _filterEngineerName;
  String? _filterSiteName;
  DateTime _focusedDate = DateTime.now();

  // Track the last load parameters so we can reload after mutations.
  bool _lastIsAdmin = false;
  String? _lastUserId;

  // ── Getters ──────────────────────────────────────────────────────────────

  /// Returns the schedule list filtered by the current engineer-name and
  /// site-name filters. Both filters are applied together when set.
  List<ScheduleModel> get schedules {
    List<ScheduleModel> filtered = List<ScheduleModel>.from(_schedules);

    if (_filterEngineerName != null && _filterEngineerName!.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.engineerName.toLowerCase() ==
                _filterEngineerName!.toLowerCase(),
          )
          .toList();
    }

    if (_filterSiteName != null && _filterSiteName!.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.siteName.toLowerCase() == _filterSiteName!.toLowerCase(),
          )
          .toList();
    }

    return filtered;
  }

  List<ScheduleModel> get allSchedules => _schedules;

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get filterEngineerName => _filterEngineerName;

  String? get filterSiteName => _filterSiteName;

  DateTime get focusedDate => _focusedDate;

  /// Distinct engineer names from the unfiltered schedule list, sorted.
  List<String> get uniqueEngineerNames {
    final names = _schedules.map((s) => s.engineerName).toSet().toList();
    names.sort();
    return names;
  }

  /// Distinct site names from the unfiltered schedule list, sorted.
  List<String> get uniqueSiteNames {
    final sites = _schedules.map((s) => s.siteName).toSet().toList();
    sites.sort();
    return sites;
  }

  // ── Load methods ─────────────────────────────────────────────────────────

  /// Loads schedules. Admins get all schedules; regular users get only their
  /// own (identified by [userId]).
  Future<void> loadSchedules({required bool isAdmin, String? userId}) async {
    _isLoading = true;
    _error = null;
    _lastIsAdmin = isAdmin;
    _lastUserId = userId;
    notifyListeners();

    try {
      if (isAdmin) {
        _schedules = await _repository.getAllSchedules();
      } else if (userId != null && userId.isNotEmpty) {
        _schedules = await _repository.getSchedulesForUser(userId);
      } else {
        _schedules = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads schedules within a date range. Admins see all; users see their own.
  Future<void> loadSchedulesByDateRange(
    DateTime start,
    DateTime end, {
    required bool isAdmin,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    _lastIsAdmin = isAdmin;
    _lastUserId = userId;
    notifyListeners();

    try {
      if (isAdmin) {
        _schedules = await _repository.getSchedulesByDateRange(start, end);
      } else if (userId != null && userId.isNotEmpty) {
        _schedules = await _repository.getSchedulesByDateRange(
          start,
          end,
          userId: userId,
        );
      } else {
        _schedules = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CRUD methods (admin only) ────────────────────────────────────────────

  /// Creates a new schedule entry. Returns `true` on success.
  Future<bool> addSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createSchedule(schedule);
      await loadSchedules(isAdmin: _lastIsAdmin, userId: _lastUserId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing schedule entry. Returns `true` on success.
  Future<bool> updateSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateSchedule(schedule);
      await loadSchedules(isAdmin: _lastIsAdmin, userId: _lastUserId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a schedule entry by [id]. Returns `true` on success.
  Future<bool> deleteSchedule(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteSchedule(id);
      await loadSchedules(isAdmin: _lastIsAdmin, userId: _lastUserId);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Filter methods ───────────────────────────────────────────────────────

  void setFilterEngineerName(String? name) {
    _filterEngineerName = name;
    notifyListeners();
  }

  void setFilterSiteName(String? site) {
    _filterSiteName = site;
    notifyListeners();
  }

  void setFocusedDate(DateTime date) {
    _focusedDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _filterEngineerName = null;
    _filterSiteName = null;
    notifyListeners();
  }

  /// Resets in-memory schedules and filters (e.g., on sign-out).
  void reset() {
    _schedules = [];
    _error = null;
    _filterEngineerName = null;
    _filterSiteName = null;
    _focusedDate = DateTime.now();
    _lastIsAdmin = false;
    _lastUserId = null;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns filtered schedules whose date matches [date] (year-month-day).
  List<ScheduleModel> getSchedulesForDate(DateTime date) {
    return schedules.where((s) {
      return s.scheduleDate.year == date.year &&
          s.scheduleDate.month == date.month &&
          s.scheduleDate.day == date.day;
    }).toList();
  }

  /// Returns filtered schedules for the ISO week containing [referenceDate]
  /// (Monday through Sunday).
  List<ScheduleModel> getSchedulesForWeek(DateTime referenceDate) {
    final monday =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return schedules.where((s) {
      return !s.scheduleDate.isBefore(startOfWeek) &&
          !s.scheduleDate.isAfter(endOfWeek);
    }).toList();
  }
}
