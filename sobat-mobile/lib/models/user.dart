class User {
  final int id;
  final String name;
  final String email;
  final String? employeeId;
  final String? avatar;
  final String? role;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasPin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId,
    this.avatar,
    this.role,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.hasPin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      employeeId: json['employee_id'] as String?,
      avatar: json['avatar'] as String?,
      role: json['role'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      hasPin: json['has_pin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'employee_id': employeeId,
      'avatar': avatar,
      'role': role,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'has_pin': hasPin,
    };
  }

  // Helper method untuk check role
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isEmployee => role == 'employee';
}
