import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zonal_models.dart';

/// Service managing API calls to Supabase for the "My Zonal" module:
/// - Retail Outlet Sites (OWP, TPT, WIM)
/// - Maintenance Complaints
/// - 4-Nozzle Cash Verifications & Reconciliations
class ZonalService {
  final SupabaseClient _client;

  ZonalService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ─── Sites ──────────────────────────────────────────────────────────────────

  Future<List<Site>> fetchSites() async {
    final response = await _client
        .from('sites')
        .select('*')
        .order('id', ascending: true);
    return (response as List)
        .map((row) => Site.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  // ─── Maintenance Complaints ─────────────────────────────────────────────────

  /// Fetches complaints with optional filters for site, priority, and status.
  Future<List<MaintenanceComplaint>> fetchComplaints({
    String? siteId,
    String? priority,
    String? status,
  }) async {
    var query = _client.from('maintenance_complaints').select('*');

    if (siteId != null && siteId.isNotEmpty && siteId != 'ALL') {
      query = query.eq('site_id', siteId);
    }
    if (priority != null && priority.isNotEmpty && priority != 'ALL') {
      query = query.eq('priority', priority);
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query = query.eq('status', status);
    }

    final response = await query
        .order('site_id', ascending: true)
        .order('s_no', ascending: true);

    return (response as List)
        .map((row) => MaintenanceComplaint.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Updates complaint status. If status is 'Completed', automatically sets
  /// completed_date = CURRENT_DATE.
  Future<MaintenanceComplaint> updateComplaintStatus(
    String id,
    String status,
  ) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'Completed') {
      updateData['completed_date'] =
          DateTime.now().toIso8601String().split('T').first;
    } else {
      updateData['completed_date'] = null;
    }

    final response = await _client
        .from('maintenance_complaints')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return MaintenanceComplaint.fromMap(Map<String, dynamic>.from(response));
  }

  /// Inserts a new maintenance complaint record.
  Future<MaintenanceComplaint> insertComplaint(
    Map<String, dynamic> complaintData,
  ) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(complaintData);
    if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
      final site = data['site_id'] ?? 'GEN';
      final stamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      data['id'] = 'MNT-$site-$stamp';
    }

    final response = await _client
        .from('maintenance_complaints')
        .insert(data)
        .select()
        .single();

    return MaintenanceComplaint.fromMap(Map<String, dynamic>.from(response));
  }

  /// Deletes a maintenance complaint by ID.
  Future<void> deleteComplaint(String id) async {
    await _client.from('maintenance_complaints').delete().eq('id', id);
  }

  /// Subscribes to realtime Postgres changes for complaints.
  RealtimeChannel subscribeToComplaints(void Function() onUpdate) {
    final channel = _client.channel('complaints-changes');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'maintenance_complaints',
      callback: (payload) {
        onUpdate();
      },
    );
    channel.subscribe();
    return channel;
  }

  // ─── Cash Verification Functions ────────────────────────────────────────────

  /// Submits a full cash verification with header and 4 nozzle records.
  Future<CashVerification> submitCashVerification(
    Map<String, dynamic> headerData,
    List<Map<String, dynamic>> nozzlesArray,
  ) async {
    // 1. Insert header record and retrieve ID
    final headerResponse = await _client
        .from('cash_verifications')
        .insert(headerData)
        .select()
        .single();

    final verificationId = headerResponse['id']?.toString();
    if (verificationId == null) {
      throw Exception('Failed to obtain verification ID');
    }

    // 2. Prepare and insert nozzle records with linked verificationId
    final List<Map<String, dynamic>> nozzleRows = [];
    for (final nozzle in nozzlesArray) {
      final row = Map<String, dynamic>.from(nozzle);
      row['verification_id'] = verificationId;
      // generated column sale_amount is computed by postgres, omit if present
      row.remove('sale_amount');
      row.remove('id');
      nozzleRows.add(row);
    }

    final nozzlesResponse = await _client
        .from('cash_verification_nozzles')
        .insert(nozzleRows)
        .select();

    final nozzles = (nozzlesResponse as List)
        .map((n) => CashVerificationNozzle.fromMap(Map<String, dynamic>.from(n)))
        .toList();

    return CashVerification.fromMap(
      Map<String, dynamic>.from(headerResponse),
      nozzles,
    );
  }

  /// Fetches verification history joined with nozzle details.
  Future<List<CashVerification>> fetchVerificationHistory({
    String? siteId,
  }) async {
    var query = _client.from('cash_verifications').select(
      '*, cash_verification_nozzles(*)',
    );

    if (siteId != null && siteId.isNotEmpty && siteId != 'ALL') {
      query = query.eq('site_id', siteId);
    }

    final response = await query.order('created_at', ascending: false).limit(50);

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row);
      final rawNozzles = map['cash_verification_nozzles'] as List? ?? [];
      final nozzles = rawNozzles
          .map((n) => CashVerificationNozzle.fromMap(Map<String, dynamic>.from(n)))
          .toList()
        ..sort((a, b) => a.nozzleName.compareTo(b.nozzleName));

      return CashVerification.fromMap(map, nozzles);
    }).toList();
  }
}
