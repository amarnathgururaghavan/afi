class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  /// Whether this user has the admin role.
  bool get isAdmin => role == 'admin';

  /// Creates a [ProfileModel] from a Supabase JSON row.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converts this model to a JSON map suitable for Supabase insert/update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Returns a copy of this model with the given fields replaced.
  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, fullName, role, createdAt);
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, email: $email, fullName: $fullName, '
        'role: $role, createdAt: $createdAt)';
  }
}
