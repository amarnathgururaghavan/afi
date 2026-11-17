/// Models representing Retail Outlets, Maintenance Complaints, and Cash Verifications
/// for the "My Zonal" module.

class Site {
  final String id;
  final String name;
  final String state;
  final String zone;

  const Site({
    required this.id,
    required this.name,
    this.state = 'Tamil Nadu',
    this.zone = 'TN-V',
  });

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      state: map['state']?.toString() ?? 'Tamil Nadu',
      zone: map['zone']?.toString() ?? 'TN-V',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'zone': zone,
    };
  }
}

class MaintenanceComplaint {
  final String id;
  final String siteId;
  final int? sNo;
  final String equipment;
  final String category;
  final String problem;
  final String priority;
  final String? reportedBy;
  final String? responsiblePerson;
  final String? actionTaken;
  final String? vendor;
  final DateTime? complaintDate;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final String status;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaintenanceComplaint({
    required this.id,
    required this.siteId,
    this.sNo,
    required this.equipment,
    required this.category,
    required this.problem,
    required this.priority,
    this.reportedBy,
    this.responsiblePerson,
    this.actionTaken,
    this.vendor,
    this.complaintDate,
    this.dueDate,
    this.completedDate,
    this.status = 'Pending',
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceComplaint.fromMap(Map<String, dynamic> map) {
    return MaintenanceComplaint(
      id: map['id']?.toString() ?? '',
      siteId: map['site_id']?.toString() ?? '',
      sNo: map['s_no'] != null ? int.tryParse(map['s_no'].toString()) : null,
      equipment: map['equipment']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      problem: map['problem']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'P3 - Medium',
      reportedBy: map['reported_by']?.toString(),
      responsiblePerson: map['responsible_person']?.toString(),
      actionTaken: map['action_taken']?.toString(),
      vendor: map['vendor']?.toString(),
      complaintDate: map['complaint_date'] != null
          ? DateTime.tryParse(map['complaint_date'].toString())
          : null,
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      completedDate: map['completed_date'] != null
          ? DateTime.tryParse(map['completed_date'].toString())
          : null,
      status: map['status']?.toString() ?? 'Pending',
      remarks: map['remarks']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      if (sNo != null) 's_no': sNo,
      'equipment': equipment,
      'category': category,
      'problem': problem,
      'priority': priority,
      if (reportedBy != null) 'reported_by': reportedBy,
      if (responsiblePerson != null) 'responsible_person': responsiblePerson,
      if (actionTaken != null) 'action_taken': actionTaken,
      if (vendor != null) 'vendor': vendor,
      if (complaintDate != null)
        'complaint_date': complaintDate!.toIso8601String().split('T').first,
      if (dueDate != null)
        'due_date': dueDate!.toIso8601String().split('T').first,
      if (completedDate != null)
        'completed_date': completedDate!.toIso8601String().split('T').first,
      'status': status,
      if (remarks != null) 'remarks': remarks,
    };
  }

  bool get isCritical => priority.startsWith('P1');
  bool get isHigh => priority.startsWith('P2');
  bool get isMedium => priority.startsWith('P3');
  bool get isLow => priority.startsWith('P4');

  String get nextStatus {
    switch (status) {
      case 'Pending':
        return 'In Progress';
      case 'In Progress':
        return 'Completed';
      case 'Completed':
      default:
        return 'Pending';
    }
  }
}

class CashVerification {
  final String id;
  final String siteId;
  final DateTime entryDate;
  final String entryTime;
  final String manualStatus;
  final double totalSales;
  final double totalCash;
  final double totalCard;
  final double totalUpi;
  final double totalOtherExp;
  final double netDifference;
  final String? remarks;
  final DateTime? createdAt;
  final List<CashVerificationNozzle> nozzles;

  const CashVerification({
    required this.id,
    required this.siteId,
    required this.entryDate,
    required this.entryTime,
    this.manualStatus = 'okay',
    this.totalSales = 0.0,
    this.totalCash = 0.0,
    this.totalCard = 0.0,
    this.totalUpi = 0.0,
    this.totalOtherExp = 0.0,
    this.netDifference = 0.0,
    this.remarks,
    this.createdAt,
    this.nozzles = const [],
  });

  factory CashVerification.fromMap(
    Map<String, dynamic> map, [
    List<CashVerificationNozzle> nozzlesList = const [],
  ]) {
    return CashVerification(
      id: map['id']?.toString() ?? '',
      siteId: map['site_id']?.toString() ?? '',
      entryDate: map['entry_date'] != null
          ? DateTime.parse(map['entry_date'].toString())
          : DateTime.now(),
      entryTime: map['entry_time']?.toString() ?? '12:00:00',
      manualStatus: map['manual_status']?.toString() ?? 'okay',
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalCash: (map['total_cash'] as num?)?.toDouble() ?? 0.0,
      totalCard: (map['total_card'] as num?)?.toDouble() ?? 0.0,
      totalUpi: (map['total_upi'] as num?)?.toDouble() ?? 0.0,
      totalOtherExp: (map['total_other_exp'] as num?)?.toDouble() ?? 0.0,
      netDifference: (map['net_difference'] as num?)?.toDouble() ?? 0.0,
      remarks: map['remarks']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      nozzles: nozzlesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'entry_date': entryDate.toIso8601String().split('T').first,
      'entry_time': entryTime,
      'manual_status': manualStatus,
      'total_sales': totalSales,
      'total_cash': totalCash,
      'total_card': totalCard,
      'total_upi': totalUpi,
      'total_other_exp': totalOtherExp,
      'net_difference': netDifference,
      if (remarks != null) 'remarks': remarks,
    };
  }
}

class CashVerificationNozzle {
  final String? id;
  final String? verificationId;
  final String nozzleName; // 'A1', 'A2', 'B1', 'B2'
  final double openingReading;
  final double closingReading;
  final double saleAmount;
  final double cardAmount;
  final double upiAmount;
  final double otherExpAmount;
  final String? otherExpRemark;
  final Map<String, int> denominations;
  final double cashTotal;
  final double difference;

  const CashVerificationNozzle({
    this.id,
    this.verificationId,
    required this.nozzleName,
    this.openingReading = 0.0,
    this.closingReading = 0.0,
    this.saleAmount = 0.0,
    this.cardAmount = 0.0,
    this.upiAmount = 0.0,
    this.otherExpAmount = 0.0,
    this.otherExpRemark,
    this.denominations = const {},
    this.cashTotal = 0.0,
    this.difference = 0.0,
  });

  factory CashVerificationNozzle.fromMap(Map<String, dynamic> map) {
    Map<String, int> denomMap = {};
    if (map['denominations'] is Map) {
      (map['denominations'] as Map).forEach((k, v) {
        denomMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    return CashVerificationNozzle(
      id: map['id']?.toString(),
      verificationId: map['verification_id']?.toString(),
      nozzleName: map['nozzle_name']?.toString() ?? 'A1',
      openingReading: (map['opening_reading'] as num?)?.toDouble() ?? 0.0,
      closingReading: (map['closing_reading'] as num?)?.toDouble() ?? 0.0,
      saleAmount: (map['sale_amount'] as num?)?.toDouble() ?? 0.0,
      cardAmount: (map['card_amount'] as num?)?.toDouble() ?? 0.0,
      upiAmount: (map['upi_amount'] as num?)?.toDouble() ?? 0.0,
      otherExpAmount: (map['other_exp_amount'] as num?)?.toDouble() ?? 0.0,
      otherExpRemark: map['other_exp_remark']?.toString(),
      denominations: denomMap,
      cashTotal: (map['cash_total'] as num?)?.toDouble() ?? 0.0,
      difference: (map['difference'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap([String? linkedVerificationId]) {
    return {
      if (id != null) 'id': id,
      if (linkedVerificationId != null || verificationId != null)
        'verification_id': linkedVerificationId ?? verificationId,
      'nozzle_name': nozzleName,
      'opening_reading': openingReading,
      'closing_reading': closingReading,
      'card_amount': cardAmount,
      'upi_amount': upiAmount,
      'other_exp_amount': otherExpAmount,
      if (otherExpRemark != null) 'other_exp_remark': otherExpRemark,
      'denominations': denominations,
      'cash_total': cashTotal,
      'difference': difference,
    };
  }
}
