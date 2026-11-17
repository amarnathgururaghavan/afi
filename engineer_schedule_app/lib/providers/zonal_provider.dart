import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zonal_models.dart';
import '../services/zonal_service.dart';

class SiteBreakdown {
  final String siteId;
  final String siteName;
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int critical;

  const SiteBreakdown({
    required this.siteId,
    required this.siteName,
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.critical = 0,
  });
}

class NozzleFormState {
  double openingReading = 0.0;
  double closingReading = 0.0;
  double cardAmount = 0.0;
  double upiAmount = 0.0;
  double otherExpAmount = 0.0;
  String otherExpRemark = '';
  Map<String, int> denominations = {
    '500': 0,
    '200': 0,
    '100': 0,
    '50': 0,
    '20': 0,
    '10': 0,
    'coins': 0,
  };

  double get saleAmount {
    if (closingReading >= openingReading) {
      return closingReading - openingReading;
    }
    return 0.0;
  }

  double get cashTotal {
    double total = 0;
    total += (denominations['500'] ?? 0) * 500;
    total += (denominations['200'] ?? 0) * 200;
    total += (denominations['100'] ?? 0) * 100;
    total += (denominations['50'] ?? 0) * 50;
    total += (denominations['20'] ?? 0) * 20;
    total += (denominations['10'] ?? 0) * 10;
    total += (denominations['coins'] ?? 0);
    return total;
  }

  double get totalCollected => cashTotal + cardAmount + upiAmount + otherExpAmount;

  double get difference => totalCollected - saleAmount;

  void reset() {
    openingReading = 0.0;
    closingReading = 0.0;
    cardAmount = 0.0;
    upiAmount = 0.0;
    otherExpAmount = 0.0;
    otherExpRemark = '';
    denominations = {
      '500': 0,
      '200': 0,
      '100': 0,
      '50': 0,
      '20': 0,
      '10': 0,
      'coins': 0,
    };
  }
}

class ZonalProvider extends ChangeNotifier {
  final ZonalService _service;
  RealtimeChannel? _subscription;

  ZonalProvider({ZonalService? service})
      : _service = service ?? ZonalService() {
    _initNozzles();
  }

  // ─── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;

  List<Site> _sites = [
    const Site(id: 'OWP', name: 'Old Washermanpet'),
    const Site(id: 'TPT', name: 'Tondiarpet'),
    const Site(id: 'WIM', name: 'Wimco Nagar'),
  ];

  List<MaintenanceComplaint> _allComplaints = [];

  // Filters
  String _filterSiteId = 'ALL';
  String _filterPriority = 'ALL';
  String _filterStatus = 'ALL';
  String _searchQuery = '';

  // Cash Checking Form State
  String _cashSiteId = 'OWP';
  DateTime _cashEntryDate = DateTime.now();
  String _cashRemarks = '';
  int _activeNozzleIndex = 0; // 0=A1, 1=A2, 2=B1, 3=B2
  final List<String> nozzleNames = ['A1', 'A2', 'B1', 'B2'];
  final Map<String, NozzleFormState> _nozzleForms = {};

  List<CashVerification> _history = [];
  bool _isSubmittingCash = false;

  void _initNozzles() {
    for (final name in nozzleNames) {
      _nozzleForms[name] = NozzleFormState();
    }
  }

  // ─── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Site> get sites => _sites;
  String get filterSiteId => _filterSiteId;
  String get filterPriority => _filterPriority;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  List<MaintenanceComplaint> get filteredComplaints {
    return _allComplaints.where((c) {
      if (_filterSiteId != 'ALL' && c.siteId != _filterSiteId) return false;
      if (_filterPriority != 'ALL' && c.priority != _filterPriority) return false;
      if (_filterStatus != 'ALL' && c.status != _filterStatus) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchEquipment = c.equipment.toLowerCase().contains(q);
        final matchCategory = c.category.toLowerCase().contains(q);
        final matchProblem = c.problem.toLowerCase().contains(q);
        final matchVendor = c.vendor?.toLowerCase().contains(q) ?? false;
        final matchReportedBy = c.reportedBy?.toLowerCase().contains(q) ?? false;
        final matchId = c.id.toLowerCase().contains(q);
        if (!matchEquipment &&
            !matchCategory &&
            !matchProblem &&
            !matchVendor &&
            !matchReportedBy &&
            !matchId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  SiteBreakdown getSiteBreakdown(String siteId, String defaultName) {
    final list = _allComplaints.where((c) => c.siteId == siteId);
    final total = list.length;
    final pending = list.where((c) => c.status == 'Pending').length;
    final inProgress = list.where((c) => c.status == 'In Progress').length;
    final completed = list.where((c) => c.status == 'Completed').length;
    final critical = list.where((c) => c.isCritical && c.status != 'Completed').length;

    return SiteBreakdown(
      siteId: siteId,
      siteName: defaultName,
      total: total,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      critical: critical,
    );
  }

  // Cash Checking Getters
  String get cashSiteId => _cashSiteId;
  DateTime get cashEntryDate => _cashEntryDate;
  String get cashRemarks => _cashRemarks;
  int get activeNozzleIndex => _activeNozzleIndex;
  String get activeNozzleName => nozzleNames[_activeNozzleIndex];
  NozzleFormState get activeNozzleForm => _nozzleForms[activeNozzleName]!;
  Map<String, NozzleFormState> get nozzleForms => _nozzleForms;
  List<CashVerification> get history => _history;
  bool get isSubmittingCash => _isSubmittingCash;

  double get totalSales =>
      _nozzleForms.values.fold(0.0, (acc, n) => acc + n.saleAmount);

  double get totalCash =>
      _nozzleForms.values.fold(0.0, (acc, n) => acc + n.cashTotal);

  double get totalCard =>
      _nozzleForms.values.fold(0.0, (acc, n) => acc + n.cardAmount);

  double get totalUpi =>
      _nozzleForms.values.fold(0.0, (acc, n) => acc + n.upiAmount);

  double get totalOtherExp =>
      _nozzleForms.values.fold(0.0, (acc, n) => acc + n.otherExpAmount);

  double get overallNetDifference =>
      (totalCash + totalCard + totalUpi + totalOtherExp) - totalSales;

  String get computedManualStatus {
    final diff = overallNetDifference;
    if (diff.abs() < 0.01) return 'okay';
    if (diff < 0) return 'shortage';
    return 'excess';
  }

  // ─── Initialization & Loading ───────────────────────────────────────────────

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedSites = await _service.fetchSites();
      if (fetchedSites.isNotEmpty) {
        _sites = fetchedSites;
      }
      await loadComplaints();
      await loadHistory();
      _setupRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtime() {
    _subscription?.unsubscribe();
    try {
      _subscription = _service.subscribeToComplaints(() {
        loadComplaints(silent: true);
      });
    } catch (e) {
      debugPrint('Realtime subscription not available or failed: $e');
    }
  }

  Future<void> loadComplaints({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _allComplaints = await _service.fetchComplaints();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await _service.fetchVerificationHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading verification history: $e');
    }
  }

  // ─── Filter Mutators ────────────────────────────────────────────────────────

  void setFilterSite(String siteId) {
    _filterSiteId = siteId;
    notifyListeners();
  }

  void setFilterPriority(String priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterSiteId = 'ALL';
    _filterPriority = 'ALL';
    _filterStatus = 'ALL';
    _searchQuery = '';
    notifyListeners();
  }

  // ─── Complaint CRUD & Cycling ───────────────────────────────────────────────

  /// Quick one-click status cycling (Pending -> In Progress -> Completed).
  Future<void> cycleComplaintStatus(MaintenanceComplaint complaint) async {
    final next = complaint.nextStatus;
    // Optimistic UI update
    final index = _allComplaints.indexWhere((c) => c.id == complaint.id);
    if (index != -1) {
      _allComplaints[index] = MaintenanceComplaint(
        id: complaint.id,
        siteId: complaint.siteId,
        sNo: complaint.sNo,
        equipment: complaint.equipment,
        category: complaint.category,
        problem: complaint.problem,
        priority: complaint.priority,
        reportedBy: complaint.reportedBy,
        responsiblePerson: complaint.responsiblePerson,
        actionTaken: complaint.actionTaken,
        vendor: complaint.vendor,
        complaintDate: complaint.complaintDate,
        dueDate: complaint.dueDate,
        completedDate: next == 'Completed' ? DateTime.now() : null,
        status: next,
        remarks: complaint.remarks,
        createdAt: complaint.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }

    try {
      final updated = await _service.updateComplaintStatus(complaint.id, next);
      if (index != -1) {
        _allComplaints[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to cycle status: $e';
      await loadComplaints(silent: true);
    }
  }

  Future<void> addComplaint(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newComplaint = await _service.insertComplaint(data);
      _allComplaints.insert(0, newComplaint);
      _error = null;
    } catch (e) {
      _error = 'Failed to add complaint: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteComplaint(String id) async {
    _allComplaints.removeWhere((c) => c.id == id);
    notifyListeners();

    try {
      await _service.deleteComplaint(id);
    } catch (e) {
      _error = 'Failed to delete complaint: $e';
      await loadComplaints(silent: true);
      rethrow;
    }
  }

  // ─── Cash Checking Form Mutators ────────────────────────────────────────────

  void setCashSiteId(String siteId) {
    _cashSiteId = siteId;
    notifyListeners();
  }

  void setCashEntryDate(DateTime date) {
    _cashEntryDate = date;
    notifyListeners();
  }

  void setCashRemarks(String remarks) {
    _cashRemarks = remarks;
    notifyListeners();
  }

  void setActiveNozzleIndex(int index) {
    if (index >= 0 && index < nozzleNames.length) {
      _activeNozzleIndex = index;
      notifyListeners();
    }
  }

  void updateNozzleReadings({
    required String nozzleName,
    required double opening,
    required double closing,
  }) {
    final form = _nozzleForms[nozzleName];
    if (form != null) {
      form.openingReading = opening;
      form.closingReading = closing;
      notifyListeners();
    }
  }

  void updateNozzleNonCash({
    required String nozzleName,
    double? card,
    double? upi,
    double? otherExp,
    String? remark,
  }) {
    final form = _nozzleForms[nozzleName];
    if (form != null) {
      if (card != null) form.cardAmount = card;
      if (upi != null) form.upiAmount = upi;
      if (otherExp != null) form.otherExpAmount = otherExp;
      if (remark != null) form.otherExpRemark = remark;
      notifyListeners();
    }
  }

  void updateNozzleDenomination({
    required String nozzleName,
    required String denomKey,
    required int count,
  }) {
    final form = _nozzleForms[nozzleName];
    if (form != null) {
      form.denominations[denomKey] = count;
      notifyListeners();
    }
  }

  void resetCashForm() {
    _cashRemarks = '';
    for (final form in _nozzleForms.values) {
      form.reset();
    }
    _activeNozzleIndex = 0;
    notifyListeners();
  }

  Future<void> submitCashVerification() async {
    _isSubmittingCash = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final header = {
        'site_id': _cashSiteId,
        'entry_date': _cashEntryDate.toIso8601String().split('T').first,
        'entry_time': timeStr,
        'manual_status': computedManualStatus,
        'total_sales': totalSales,
        'total_cash': totalCash,
        'total_card': totalCard,
        'total_upi': totalUpi,
        'total_other_exp': totalOtherExp,
        'net_difference': overallNetDifference,
        'remarks': _cashRemarks.isNotEmpty ? _cashRemarks : null,
      };

      final List<Map<String, dynamic>> nozzlesList = [];
      for (final name in nozzleNames) {
        final form = _nozzleForms[name]!;
        nozzlesList.add({
          'nozzle_name': name,
          'opening_reading': form.openingReading,
          'closing_reading': form.closingReading,
          'card_amount': form.cardAmount,
          'upi_amount': form.upiAmount,
          'other_exp_amount': form.otherExpAmount,
          'other_exp_remark': form.otherExpRemark.isNotEmpty ? form.otherExpRemark : null,
          'denominations': form.denominations,
          'cash_total': form.cashTotal,
          'difference': form.difference,
        });
      }

      final created = await _service.submitCashVerification(header, nozzlesList);
      _history.insert(0, created);
      resetCashForm();
    } catch (e) {
      _error = 'Failed to submit cash verification: $e';
      rethrow;
    } finally {
      _isSubmittingCash = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
