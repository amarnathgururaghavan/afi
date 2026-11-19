import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maintenance_note_model.dart';
import '../services/maintenance_notes_service.dart';

/// Represents a grouped site cluster of maintenance notes with summary metrics.
class SiteNotesGroup {
  final String siteName;
  final List<MaintenanceNote> notes;

  const SiteNotesGroup({
    required this.siteName,
    required this.notes,
  });

  int get totalCount => notes.length;
  int get openCount => notes.where((n) => !n.isClosed).length;
  int get closedCount => notes.where((n) => n.isClosed).length;
  int get sparePendingCount => notes.where((n) => n.isSparePending).length;
  int get approvalPendingCount => notes.where((n) => n.isApprovalPending).length;
}

class MaintenanceNotesProvider extends ChangeNotifier {
  final MaintenanceNotesService _service;
  RealtimeChannel? _subscription;

  MaintenanceNotesProvider({MaintenanceNotesService? service})
      : _service = service ?? MaintenanceNotesService();

  List<MaintenanceNote> _allNotes = [];
  bool _isLoading = false;
  String? _error;

  // Filters & Search
  String _filterSite = 'ALL';
  String _filterStatus = 'ALL';
  bool _hideClosed = false;
  String _searchQuery = '';

  // Track expanded/collapsed sites (by default all sites are expanded)
  final Set<String> _collapsedSites = {};

  // ─── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MaintenanceNote> get allNotes => _allNotes;
  String get filterSite => _filterSite;
  String get filterStatus => _filterStatus;
  bool get hideClosed => _hideClosed;
  String get searchQuery => _searchQuery;

  bool isSiteExpanded(String siteName) => !_collapsedSites.contains(siteName);

  /// Unique site names that currently have maintenance notes.
  List<String> get noteSites {
    final sites = _allNotes.map((n) => n.siteName).toSet().toList();
    sites.sort();
    return sites;
  }

  /// Filtered flat list of notes according to active filters and search query.
  List<MaintenanceNote> get filteredNotes {
    return _allNotes.where((note) {
      // 1. Site Filter
      if (_filterSite != 'ALL' &&
          note.siteName.toLowerCase() != _filterSite.toLowerCase()) {
        return false;
      }

      // 2. Status Filter
      if (_filterStatus != 'ALL' && note.status != _filterStatus) {
        return false;
      }

      // 3. Hide Closed Toggle
      if (_hideClosed && note.isClosed) {
        return false;
      }

      // 4. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesComplaint = note.complaint.toLowerCase().contains(q);
        final matchesSite = note.siteName.toLowerCase().contains(q);
        final matchesStatus = note.status.toLowerCase().contains(q);
        final matchesCreator = note.createdBy.toLowerCase().contains(q);
        final matchesEditor = note.updatedBy.toLowerCase().contains(q);

        if (!matchesComplaint &&
            !matchesSite &&
            !matchesStatus &&
            !matchesCreator &&
            !matchesEditor) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filtered notes grouped by Site Name, sorted with sites having most active issues first.
  List<SiteNotesGroup> get groupedNotesBySite {
    final filtered = filteredNotes;
    final Map<String, List<MaintenanceNote>> map = {};

    for (final note in filtered) {
      map.putIfAbsent(note.siteName, () => []).add(note);
    }

    // Sort notes within each group newest first
    for (final list in map.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final groups = map.entries
        .map((entry) => SiteNotesGroup(siteName: entry.key, notes: entry.value))
        .toList();

    // Sort groups: sites with open issues first, then alphabetically
    groups.sort((a, b) {
      final cmp = b.openCount.compareTo(a.openCount);
      if (cmp != 0) return cmp;
      return a.siteName.compareTo(b.siteName);
    });

    return groups;
  }

  int get totalActiveCount => _allNotes.where((n) => !n.isClosed).length;
  int get totalClosedCount => _allNotes.where((n) => n.isClosed).length;

  // ─── Initialization & Loading ───────────────────────────────────────────────

  Future<void> initialize() async {
    await loadNotes();
    _setupRealtime();
  }

  void _setupRealtime() {
    _subscription?.unsubscribe();
    try {
      _subscription = _service.subscribeToNotes(() {
        loadNotes(silent: true);
      });
    } catch (e) {
      debugPrint('Notes realtime subscription failed or unavailable: $e');
    }
  }

  Future<void> loadNotes({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _allNotes = await _service.fetchNotes();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // ─── Filter & Search Mutators ───────────────────────────────────────────────

  void setFilterSite(String site) {
    _filterSite = site;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void toggleHideClosed() {
    _hideClosed = !_hideClosed;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterSite = 'ALL';
    _filterStatus = 'ALL';
    _hideClosed = false;
    _searchQuery = '';
    notifyListeners();
  }

  void toggleSiteExpanded(String siteName) {
    if (_collapsedSites.contains(siteName)) {
      _collapsedSites.remove(siteName);
    } else {
      _collapsedSites.add(siteName);
    }
    notifyListeners();
  }

  void expandAll() {
    _collapsedSites.clear();
    notifyListeners();
  }

  void collapseAll() {
    for (final note in _allNotes) {
      _collapsedSites.add(note.siteName);
    }
    notifyListeners();
  }

  // ─── CRUD Operations ────────────────────────────────────────────────────────

  Future<MaintenanceNote> addNote({
    required String siteName,
    required String complaint,
    required String status,
    required String userName,
    int? siteId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final newNote = MaintenanceNote(
        id: '',
        siteId: siteId,
        siteName: siteName.trim().toUpperCase(),
        complaint: complaint.trim(),
        status: status,
        createdBy: userName.isNotEmpty ? userName : 'Engineer',
        updatedBy: userName.isNotEmpty ? userName : 'Engineer',
        createdAt: now,
        updatedAt: now,
      );

      final inserted = await _service.createNote(newNote);
      _allNotes.insert(0, inserted);
      _error = null;
      return inserted;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MaintenanceNote> updateNote({
    required String id,
    required String siteName,
    required String complaint,
    required String status,
    required String userName,
    int? siteId,
    DateTime? createdAt,
    String? createdBy,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final noteToUpdate = MaintenanceNote(
        id: id,
        siteId: siteId,
        siteName: siteName.trim().toUpperCase(),
        complaint: complaint.trim(),
        status: status,
        createdBy: createdBy ?? userName,
        updatedBy: userName.isNotEmpty ? userName : 'Engineer',
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = await _service.updateNote(noteToUpdate);
      final index = _allNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotes[index] = updated;
      }
      _error = null;
      return updated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    final previousList = List<MaintenanceNote>.from(_allNotes);
    _allNotes.removeWhere((n) => n.id == id);
    notifyListeners();

    try {
      await _service.deleteNote(id);
    } catch (e) {
      _allNotes = previousList;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
