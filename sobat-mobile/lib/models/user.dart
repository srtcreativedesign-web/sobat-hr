class User {
  final int id;
  final String name;
  final String email;
  final int? employeeRecordId; // Integer ID for DB relationship
  final String? employeeId; // String Code (e.g. EMP001)
  final String? avatar;
  final String? role;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? jobLevel;
  final String? track;
  final String? organization;
  final int? organizationId;
  final bool hasPin;
  final bool hasOfficeLocation;
  final DateTime? contractEnd;
  final double? officeLatitude;
  final double? officeLongitude;
  final int? officeRadius;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.employeeRecordId,
    this.employeeId,
    this.avatar,
    this.role,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.jobLevel,
    this.track,
    this.organization,
    this.organizationId,
    this.hasPin = false,
    this.hasOfficeLocation = false,
    this.contractEnd,
    this.officeLatitude,
    this.officeLongitude,
    this.officeRadius,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? empRecordId;
    String? empId;
    String? jobLvl;
    String? trk;
    String? orgName;
    int? orgId;
    bool hasLoc = false;
    double? lat;
    double? lng;
    int? rad;

    if (json['employee'] != null) {
      empRecordId = json['employee']['id']; // Store integer ID
      empId = json['employee']['employee_code'];
      jobLvl = json['employee']['job_level'];
      trk = json['employee']['track'];

      if (json['employee']['organization'] != null) {
        orgName = json['employee']['organization']['name'];
        orgId = json['employee']['organization']['id'];

        // Parse Location
        if (json['employee']['organization']['latitude'] != null) {
          lat = double.tryParse(
            json['employee']['organization']['latitude'].toString(),
          );
          lng = double.tryParse(
            json['employee']['organization']['longitude'].toString(),
          );
          rad = int.tryParse(
            json['employee']['organization']['radius_meters'].toString(),
          );
          hasLoc = lat != null && lng != null;
        }
      } else {
        orgId = json['employee']['organization_id'];
      }
    } else {
      empId = json['employee_id'];
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      employeeRecordId: empRecordId,
      employeeId: empId,
      avatar: json['avatar'] as String?,
      role: (json['role'] is Map)
          ? json['role']['name'] as String?
          : json['role'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      jobLevel: jobLvl,
      track: trk,
      organization: orgName,
      organizationId: orgId,
      hasPin: json['has_pin'] as bool? ?? false,
      hasOfficeLocation: hasLoc,
      contractEnd:
          (json['employee'] != null &&
              json['employee']['contract_end_date'] != null)
          ? DateTime.parse(json['employee']['contract_end_date'])
          : null,
      officeLatitude: lat,
      officeLongitude: lng,
      officeRadius: rad,
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
      'job_level': jobLevel,
      'track': track,
      'organization': organization,
      'organization_id': organizationId,
    };
  }

  // Helper method untuk check role
  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isEmployee => role == 'employee';
}
