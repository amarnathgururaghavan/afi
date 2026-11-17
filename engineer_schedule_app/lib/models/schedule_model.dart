class ScheduleModel {
  final String id;
  final String userId;
  final String engineerName;
  final DateTime scheduleDate;
  final String siteName;
  final DateTime? createdAt;

  const ScheduleModel({
    required this.id,
    required this.userId,
    required this.engineerName,
    required this.scheduleDate,
    required this.siteName,
    this.createdAt,
  });

  /// Formats [scheduleDate] as an ISO-8601 date string (`YYYY-MM-DD`).
  String get formattedIsoDate {
    final y = scheduleDate.year.toString().padLeft(4, '0');
    final m = scheduleDate.month.toString().padLeft(2, '0');
    final d = scheduleDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Creates a [ScheduleModel] from a Supabase or repository JSON row.
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      engineerName: json['engineer_name'] as String,
      scheduleDate: DateTime.parse(json['schedule_date'] as String),
      siteName: json['site_name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts this model to a full JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'engineer_name': engineerName,
      'schedule_date': formattedIsoDate,
      'site_name': siteName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Converts this model to a JSON payload for inserting a new row.
  /// Omits server-generated fields (`id` and `created_at`).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'engineer_name': engineerName,
      'schedule_date': formattedIsoDate,
      'site_name': siteName,
    };
  }

  /// Converts this model to a JSON payload for updating an existing row.
  Map<String, dynamic> toUpdateJson() {
    return {
      'user_id': userId,
      'engineer_name': engineerName,
      'schedule_date': formattedIsoDate,
      'site_name': siteName,
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  ScheduleModel copyWith({
    String? id,
    String? userId,
    String? engineerName,
    DateTime? scheduleDate,
    String? siteName,
    DateTime? createdAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      engineerName: engineerName ?? this.engineerName,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      siteName: siteName ?? this.siteName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleModel &&
        other.id == id &&
        other.userId == userId &&
        other.engineerName == engineerName &&
        other.scheduleDate == scheduleDate &&
        other.siteName == siteName &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      engineerName,
      scheduleDate,
      siteName,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'ScheduleModel(id: $id, userId: $userId, engineerName: $engineerName, '
        'scheduleDate: $scheduleDate, siteName: $siteName, createdAt: $createdAt)';
  }
}
