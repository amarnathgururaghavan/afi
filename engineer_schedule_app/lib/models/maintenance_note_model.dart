import 'package:flutter/material.dart';

/// Strictly restricted 4 status values for Maintenance Notes.
class MaintenanceNoteStatus {
  MaintenanceNoteStatus._();

  static const String opened = 'Opened';
  static const String sparePending = 'Spare Pending';
  static const String approvalPending = 'Approval Pending';
  static const String closed = 'Closed';

  static const List<String> all = [
    opened,
    sparePending,
    approvalPending,
    closed,
  ];

  /// Returns styling colors (text, background, border, icon) for the status badge.
  static StatusBadgeStyle getStyle(String status) {
    switch (status) {
      case opened:
        return const StatusBadgeStyle(
          textColor: Color(0xFFDC2626), // Vibrant Crimson Red
          backgroundColor: Color(0xFFFEE2E2), // Light Red tint
          borderColor: Color(0xFFFCA5A5),
          icon: Icons.error_outline_rounded,
        );
      case sparePending:
        return const StatusBadgeStyle(
          textColor: Color(0xFFD97706), // Warm Amber
          backgroundColor: Color(0xFFFEF3C7), // Light Amber
          borderColor: Color(0xFFFDE68A),
          icon: Icons.build_circle_outlined,
        );
      case approvalPending:
        return const StatusBadgeStyle(
          textColor: Color(0xFF2563EB), // Royal Blue
          backgroundColor: Color(0xFFDBEAFE), // Light Blue tint
          borderColor: Color(0xFF93C5FD),
          icon: Icons.pending_actions_rounded,
        );
      case closed:
      default:
        return const StatusBadgeStyle(
          textColor: Color(0xFF16A34A), // Emerald Green
          backgroundColor: Color(0xFFDCFCE7), // Light Green tint
          borderColor: Color(0xFF86EFAC),
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

class StatusBadgeStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const StatusBadgeStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

/// Data model representing a record in the `maintenance_notes` table.
class MaintenanceNote {
  final String id;
  final int? siteId;
  final String siteName;
  final String complaint;
  final String status;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceNote({
    required this.id,
    this.siteId,
    required this.siteName,
    required this.complaint,
    required this.status,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClosed => status == MaintenanceNoteStatus.closed;
  bool get isOpened => status == MaintenanceNoteStatus.opened;
  bool get isSparePending => status == MaintenanceNoteStatus.sparePending;
  bool get isApprovalPending =>
      status == MaintenanceNoteStatus.approvalPending;

  factory MaintenanceNote.fromJson(Map<String, dynamic> json) {
    return MaintenanceNote(
      id: json['id']?.toString() ?? '',
      siteId: json['site_id'] != null
          ? int.tryParse(json['site_id'].toString())
          : null,
      siteName: json['site_name']?.toString() ?? '',
      complaint: json['complaint']?.toString() ?? '',
      status: json['status']?.toString() ?? MaintenanceNoteStatus.opened,
      createdBy: json['created_by']?.toString() ?? 'System',
      updatedBy: json['updated_by']?.toString() ?? 'System',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (siteId != null) 'site_id': siteId,
      'site_name': siteName,
      'complaint': complaint,
      'status': status,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'site_name': siteName.trim().toUpperCase(),
      'complaint': complaint.trim(),
      'status': status,
      'created_by': createdBy.trim(),
      'updated_by': updatedBy.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (siteId != null) {
      map['site_id'] = siteId;
    }
    return map;
  }

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{
      'site_name': siteName.trim().toUpperCase(),
      'complaint': complaint.trim(),
      'status': status,
      'updated_by': updatedBy.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (siteId != null) {
      map['site_id'] = siteId;
    }
    return map;
  }

  MaintenanceNote copyWith({
    String? id,
    int? siteId,
    String? siteName,
    String? complaint,
    String? status,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceNote(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      complaint: complaint ?? this.complaint,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
