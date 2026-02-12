import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

import '../../services/auth_service.dart';
import '../../services/employee_service.dart';
import 'enroll_face_screen.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();

  // Basic fields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  // Focus Nodes
  final FocusNode _supervisorFocusNode = FocusNode(); // Added

  // Employee fields
  final TextEditingController _employeeIdCtrl = TextEditingController();
  final TextEditingController _placeOfBirthCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime? _joinDate;
  File? _photoFile;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (picked != null) {
        setState(() {
          _photoFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  final TextEditingController _ktpAddressCtrl = TextEditingController();
  final TextEditingController _currentAddressCtrl = TextEditingController();
  String? _gender;
  String? _religion;
  String? _maritalStatus;
  String? _ptkpStatus;
  final TextEditingController _nikCtrl = TextEditingController();
  final TextEditingController _npwpCtrl = TextEditingController();
  final TextEditingController _bankAccCtrl = TextEditingController();
  final TextEditingController _bankAccNameCtrl = TextEditingController();
  final TextEditingController _fatherNameCtrl = TextEditingController();
  final TextEditingController _motherNameCtrl = TextEditingController();
  final TextEditingController _spouseNameCtrl = TextEditingController();
  final TextEditingController _familyContactCtrl = TextEditingController();

  // Education fields
  // Mandatory
  final TextEditingController _eduSdCtrl = TextEditingController();
  final TextEditingController _eduSmpCtrl = TextEditingController();
  final TextEditingController _eduSmkCtrl = TextEditingController();
  // Optional
  final TextEditingController _eduS1Ctrl = TextEditingController();
  final TextEditingController _eduS2Ctrl = TextEditingController();
  final TextEditingController _eduS3Ctrl = TextEditingController();

  final TextEditingController _departmentCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();
  final TextEditingController _supervisorNameCtrl = TextEditingController();
  final TextEditingController _supervisorPositionCtrl = TextEditingController();
  // UI helpers
  String? _department;
  String? _position;
  // String? _track; // Removed unused field

  List<String> _ptkpOptions = [
    'TK0',
    'TK1',
    'TK2',
    'TK3',
    'K0',
    'K1',
    'K2',
    'K3',
    'K/I/0',
    'K/I/1',
    'K/I/2',
    'K/I/3',
  ];

  bool _saving = false;
  int? _employeeRecordId;
  int _joinDateEditCount = 0;

  // Dynamic Options
  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _jobPositions = [];
  bool _isLoadingDivisions = false;
  bool _isLoadingJobPositions = false;
  int? _selectedDivisionId;
  int? _selectedJobPositionId;
  int? _supervisorId; // Added

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    // 1. Fetch Divisions FIRST
    await _fetchDivisions();

    // 2. Load User Profile and Match
    await _loadInitial();
  }

  Future<void> _fetchDivisions() async {
    setState(() => _isLoadingDivisions = true);
    try {
      final dio = Dio();
      final token = await _authService.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      final response = await dio.get('${ApiConfig.baseUrl}/divisions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _divisions = data.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching divisions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDivisions = false);
    }
  }

  Future<void> _fetchJobPositions(int? divisionId) async {
    if (divisionId == null) {
      setState(() => _jobPositions = []);
      return;
    }

    setState(() => _isLoadingJobPositions = true);
    try {
      final dio = Dio();
      final token = await _authService.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      // Fetch positions for specific division
      final response = await dio.get(
        '${ApiConfig.baseUrl}/job-positions',
        queryParameters: {'division_id': divisionId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _jobPositions = data.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching job positions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingJobPositions = false);
    }
  }

  Future<void> _loadInitial() async {
    // Determine fresh profile from API first to ensure we have latest data
    await _authService.getProfile();
    final current = await _authService.getCurrentUser();

    // DEBUG: Inspect raw data
    debugPrint('EDIT PROFILE RAW USER: $current');

    if (current != null) {
      // top-level user fields
      _nameCtrl.text = current['name'] ?? '';
      _emailCtrl.text = current['email'] ?? '';
      // Phone might be in user or employee object.
      // User table has valid email/name, but phone is usually in Employee.
      _phoneCtrl.text = current['phone'] ?? '';

      // employee sub-object may exist
      final emp =
          current['employee'] ??
          current['employee_data'] ??
          current['employee_record'];

      debugPrint('EDIT PROFILE EMP DATA: $emp');

      if (emp != null && emp is Map<String, dynamic>) {
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = emp['full_name'] ?? emp['name'] ?? '';
        }
        if (_emailCtrl.text.isEmpty) {
          _emailCtrl.text = emp['email'] ?? '';
        }
        if (_phoneCtrl.text.isEmpty) {
          // Fallback to employee phone if user phone is empty
          _phoneCtrl.text = emp['phone'] ?? emp['family_contact_number'] ?? '';
        }
        _employeeRecordId = emp['id'] as int?;
        _joinDateEditCount = emp['join_date_edit_count'] ?? 0;
        _employeeIdCtrl.text = emp['employee_code'] ?? emp['employee_id'] ?? '';

        if (emp['photo_path'] != null) {
          _photoUrl = ApiConfig.getStorageUrl(emp['photo_path']);
        }

        _placeOfBirthCtrl.text = emp['place_of_birth'] ?? '';
        // Check for both 'date_of_birth' and 'birth_date'
        final dob = emp['date_of_birth'] ?? emp['birth_date'];
        if (dob != null) {
          try {
            _dateOfBirth = DateTime.parse(dob);
          } catch (_) {}
        }
        if (emp['join_date'] != null) {
          try {
            _joinDate = DateTime.parse(emp['join_date']);
          } catch (_) {}
        }
        _ktpAddressCtrl.text = emp['ktp_address'] ?? '';
        _currentAddressCtrl.text = emp['current_address'] ?? '';
        _gender = emp['gender'];
        _religion = emp['religion'];
        _maritalStatus = emp['marital_status'];
        _ptkpStatus = emp['ptkp_status'];
        _nikCtrl.text = emp['nik'] ?? '';
        _npwpCtrl.text = emp['npwp'] ?? '';
        _bankAccCtrl.text = emp['bank_account_number'] ?? '';
        _bankAccNameCtrl.text = emp['bank_account_name'] ?? '';
        _fatherNameCtrl.text = emp['father_name'] ?? '';
        _motherNameCtrl.text = emp['mother_name'] ?? '';
        _spouseNameCtrl.text = emp['spouse_name'] ?? '';
        _familyContactCtrl.text = emp['family_contact_number'] ?? '';

        // Parse education JSON
        if (emp['education'] != null) {
          try {
            if (emp['education'] is Map) {
              final edu = emp['education'];
              _eduSdCtrl.text = edu['sd'] ?? '';
              _eduSmpCtrl.text = edu['smp'] ?? '';
              _eduSmkCtrl.text = edu['smk'] ?? '';
              _eduS1Ctrl.text = edu['s1'] ?? '';
              _eduS2Ctrl.text = edu['s2'] ?? '';
              _eduS3Ctrl.text = edu['s3'] ?? '';
            } else if (emp['education'] is String) {
              // Handle legacy string data or stringified JSON
              try {
                final eduMap = jsonDecode(emp['education']);
                _eduSdCtrl.text = eduMap['sd'] ?? '';
                _eduSmpCtrl.text = eduMap['smp'] ?? '';
                _eduSmkCtrl.text = eduMap['smk'] ?? '';
                _eduS1Ctrl.text = eduMap['s1'] ?? '';
                _eduS2Ctrl.text = eduMap['s2'] ?? '';
                _eduS3Ctrl.text = eduMap['s3'] ?? '';
              } catch (_) {
                // If not JSON, put loose string in SMK/SMA as fallback or leave as is
                // For now, let's put it in SMK
                _eduSmkCtrl.text = emp['education'];
              }
            }
          } catch (_) {}
        }

        _department = emp['department'];

        // Variables needed for logic
        final userJobLevel = emp['job_level'];
        final userTrack = emp['track'];

        int? userOrgId;
        if (emp['organization'] != null && emp['organization'] is Map) {
          userOrgId = emp['organization']['id'];
        } else {
          userOrgId = emp['organization_id'];
        }

        if (userJobLevel != null && userJobLevel.toString().isNotEmpty) {
          // Format job level: staff -> Staff, team_leader -> Team Leader
          _position = userJobLevel
              .toString()
              .split('_')
              .map(
                (str) =>
                    "${str[0].toUpperCase()}${str.substring(1).toLowerCase()}",
              )
              .join(' ');
        } else {
          _position = emp['position'];
        }

        _departmentCtrl.text = _department ?? '';
        _positionCtrl.text = _position ?? '';

        // Wait for divisions to load, then try to match
        // But since _fetchDivisions is async called in initState, it might not be ready.
        // We can just try to match if _divisions is populated.
        // If not, maybe retry? For simplicity, let's assume fast loading or rely on text value fallback.

        // Match Department Name to Division ID
        // Note: _divisions should be populated by now due to sequential _initAsync
        if (_department != null && _divisions.isNotEmpty) {
          final matchedDiv = _divisions.firstWhere(
            (div) => div['name'] == _department,
            orElse: () => {},
          );

          if (matchedDiv.isNotEmpty) {
            _selectedDivisionId = matchedDiv['id'] as int;

            // Fetch positions for this division
            await _fetchJobPositions(_selectedDivisionId);

            debugPrint('DEBUG: _position from API/EMP: "$_position"');
            debugPrint('DEBUG: _jobPositions count: ${_jobPositions.length}');

            // Then match position
            if (_position != null && _jobPositions.isNotEmpty) {
              final matchedPos = _jobPositions.firstWhere((pos) {
                final posName = pos['name']?.toString().trim().toLowerCase();
                final targetPos = _position!.trim().toLowerCase();
                debugPrint('DEBUG: Compare pos "$posName" vs "$targetPos"');
                return posName == targetPos;
              }, orElse: () => {});
              if (matchedPos.isNotEmpty) {
                _selectedJobPositionId = matchedPos['id'] as int;
                debugPrint(
                  'DEBUG: Matched Job Position ID: $_selectedJobPositionId',
                );
              } else {
                debugPrint('DEBUG: No matching job position found.');
              }
            }
          }
        }
        _supervisorNameCtrl.text = emp['supervisor_name'] ?? '';
        _supervisorPositionCtrl.text = emp['supervisor_position'] ?? '';
        _supervisorId =
            emp['supervisor_id']; // Added logic to load existing supervisor_id

        // Auto-fill Supervisor if empty
        if (_supervisorNameCtrl.text.isEmpty &&
            userOrgId != null &&
            userJobLevel != null) {
          // Call API to find supervisor candidate
          try {
            final candidate = await _authService.getSupervisorCandidate(
              organizationId: userOrgId,
              jobLevel: userJobLevel.toString(),
              track: userTrack is String ? userTrack : 'office',
            );

            if (candidate != null && mounted) {
              setState(() {
                _supervisorNameCtrl.text = candidate['name'] ?? '';
                _supervisorPositionCtrl.text = candidate['position'] ?? '';
              });
            }
          } catch (e) {
            print('Supervisor lookup failed: $e');
          }
        }
      }
      setState(() {});
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickJoinDate() async {
    // Logic:
    // - If date is null (not set), allow set (count remains 0)
    // - If date is NOT null:
    //    - If count < 1, allow edit
    //    - If count >= 1, block
    if (_joinDate != null && _joinDateEditCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal bergabung hanya dapat diubah satu kali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _joinDate = picked);
  }

  DropdownMenuItem<String> _buildDropdownItem(String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _sectionCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // Prepare Payload
    Object payload;
    if (_photoFile != null) {
      // Use FormData for file upload
      final map = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'employee_code': _employeeIdCtrl.text.trim(),
        'place_of_birth': _placeOfBirthCtrl.text.trim(),
        'date_of_birth': _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : null,
        'join_date': _joinDate != null
            ? DateFormat('yyyy-MM-dd').format(_joinDate!)
            : null,
        'ktp_address': _ktpAddressCtrl.text.trim(),
        'current_address': _currentAddressCtrl.text.trim(),
        'gender': _gender,
        'religion': _religion,
        'marital_status': _maritalStatus,
        'ptkp_status': _ptkpStatus,
        'nik': _nikCtrl.text.trim(),
        'npwp': _npwpCtrl.text.trim(),
        'bank_account_number': _bankAccCtrl.text.trim(),
        'bank_account_name': _bankAccNameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'mother_name': _motherNameCtrl.text.trim(),
        'spouse_name': _spouseNameCtrl.text.trim(),
        'family_contact_number': _familyContactCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'position': _positionCtrl.text.trim(),
        'job_level': _positionCtrl.text.trim().toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'supervisor_name': _supervisorNameCtrl.text.trim(),
        'supervisor_position': _supervisorPositionCtrl.text.trim(),
        'supervisor_id': _supervisorId,
      };

      // Only add _method: PUT if we are updating (not creating)
      if (_employeeRecordId != null) {
        map['_method'] = 'PUT';
      }

      // Add education manually as array fields or json string depend on backend
      // Since FormData doesn't support nested maps well, send as JSON string if backed supports it
      // or flat keys. Let's try sending flat keys for simplicity if meaningful,
      // but education is nested.
      // BEST PRACTICE: Laravel validation for 'education' => 'nullable' usually accepts JSON string or array.
      // Let's send it as individual fields 'education[sd]', 'education[smp]' etc.
      map['education[sd]'] = _eduSdCtrl.text.trim();
      map['education[smp]'] = _eduSmpCtrl.text.trim();
      map['education[smk]'] = _eduSmkCtrl.text.trim();
      map['education[s1]'] = _eduS1Ctrl.text.trim();
      map['education[s2]'] = _eduS2Ctrl.text.trim();
      map['education[s3]'] = _eduS3Ctrl.text.trim();

      payload = FormData.fromMap(map);
      (payload as FormData).files.add(
        MapEntry(
          'photo_path',
          await MultipartFile.fromFile(
            _photoFile!.path,
            filename: 'profile.jpg',
          ),
        ),
      );
    } else {
      // Standard JSON Payload
      payload = {
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'employee_code': _employeeIdCtrl.text.trim(),
        'place_of_birth': _placeOfBirthCtrl.text.trim(),
        'date_of_birth': _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : null,
        'join_date': _joinDate != null
            ? DateFormat('yyyy-MM-dd').format(_joinDate!)
            : null,
        'ktp_address': _ktpAddressCtrl.text.trim(),
        'current_address': _currentAddressCtrl.text.trim(),
        'gender': _gender,
        'religion': _religion,
        'marital_status': _maritalStatus,
        'ptkp_status': _ptkpStatus,
        'nik': _nikCtrl.text.trim(),
        'npwp': _npwpCtrl.text.trim(),
        'bank_account_number': _bankAccCtrl.text.trim(),
        'bank_account_name': _bankAccNameCtrl.text.trim(),
        'father_name': _fatherNameCtrl.text.trim(),
        'mother_name': _motherNameCtrl.text.trim(),
        'spouse_name': _spouseNameCtrl.text.trim(),
        'family_contact_number': _familyContactCtrl.text.trim(),
        'education': {
          'sd': _eduSdCtrl.text.trim(),
          'smp': _eduSmpCtrl.text.trim(),
          'smk': _eduSmkCtrl.text.trim(),
          's1': _eduS1Ctrl.text.trim(),
          's2': _eduS2Ctrl.text.trim(),
          's3': _eduS3Ctrl.text.trim(),
        },
        'department': _departmentCtrl.text.trim(),
        'position': _positionCtrl.text.trim(),
        'job_level': _positionCtrl.text.trim().toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'supervisor_name': _supervisorNameCtrl.text.trim(),
        'supervisor_position': _supervisorPositionCtrl.text.trim(),
        'supervisor_id': _supervisorId,
      };
    }

    // Debug: print payload and target id to console
    print(
      'EditProfile: saving employeeRecordId=$_employeeRecordId payload=${payload.toString()}',
    );

    try {
      if (_employeeRecordId != null) {
        await _authService.updateEmployee(_employeeRecordId!, payload);
      } else {
        await _authService.createEmployee(payload);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      // Log full error and stacktrace for debugging
      print('EditProfile: save failed -> $e');
      print('EditProfile: stacktrace -> $st');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _employeeIdCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _ktpAddressCtrl.dispose();
    _currentAddressCtrl.dispose();
    _nikCtrl.dispose();
    _npwpCtrl.dispose();
    _bankAccCtrl.dispose();
    _bankAccNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _spouseNameCtrl.dispose();
    _familyContactCtrl.dispose();
    _departmentCtrl.dispose();
    _positionCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _supervisorFocusNode.dispose(); // Added

    _supervisorPositionCtrl.dispose();

    _eduSdCtrl.dispose();
    _eduSmpCtrl.dispose();
    _eduSmkCtrl.dispose();
    _eduS1Ctrl.dispose();
    _eduS2Ctrl.dispose();
    _eduS3Ctrl.dispose();

    // no-op for _department/_position strings
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.colorCyan.withValues(alpha: 0.5),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _photoFile != null
                            ? FileImage(_photoFile!)
                            : (_photoUrl != null
                                  ? NetworkImage(_photoUrl!) as ImageProvider
                                  : null),
                        child: (_photoFile == null && _photoUrl == null)
                            ? Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.colorCyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Face Enrollment Status (hidden for operational staff)
              Center(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _authService.getCurrentUser(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;

                    // Hide for operational track (no attendance feature)
                    final userTrack = user?['employee']?['track'];
                    if (userTrack == 'operational') {
                      return const SizedBox.shrink();
                    }

                    final isEnrolled =
                        user != null &&
                        user['employee'] != null &&
                        user['employee']['face_photo_path'] != null;

                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnrollFaceScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadInitial(); // Reload to update status
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isEnrolled
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEnrolled ? Colors.green : Colors.orange,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEnrolled ? Icons.check_circle : Icons.face,
                              color: isEnrolled ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEnrolled
                                  ? 'Wajah Terdaftar'
                                  : 'Daftarkan Wajah (Wajib)',
                              style: TextStyle(
                                color: isEnrolled
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isEnrolled) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Header inputs
              _sectionCard(
                Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        labelText: AppLocalizations.of(context)!.name,
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: 'Email',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              labelText: 'Nomor HP',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Personal data
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Data Pribadi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _employeeIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'NIK Karyawan',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _placeOfBirthCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tempat Lahir',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today),
                          labelText: 'Tanggal Lahir',
                        ),
                        child: Text(
                          _dateOfBirth == null
                              ? '-'
                              : DateFormat.yMMMMd(
                                  'id_ID',
                                ).format(_dateOfBirth!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ktpAddressCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.home),
                        labelText: 'Alamat KTP',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentAddressCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on),
                        labelText: 'Alamat Domisili',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wc),
                        labelText: 'Jenis Kelamin',
                      ),
                      items: [
                        _buildDropdownItem('male'),
                        _buildDropdownItem('female'),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _religion,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance),
                        labelText: 'Agama',
                      ),
                      items: [
                        _buildDropdownItem('Islam'),
                        _buildDropdownItem('Kristen'),
                        _buildDropdownItem('Katolik'),
                        _buildDropdownItem('Hindu'),
                        _buildDropdownItem('Buddha'),
                        _buildDropdownItem('Konghucu'),
                        _buildDropdownItem('Lainnya'),
                      ],
                      onChanged: (v) => setState(() => _religion = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _maritalStatus,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.family_restroom),
                        labelText: 'Status Perkawinan',
                      ),
                      items: [
                        _buildDropdownItem('Belum Kawin'),
                        _buildDropdownItem('Kawin'),
                        _buildDropdownItem('Cerai Hidup'),
                        _buildDropdownItem('Cerai Mati'),
                      ],
                      onChanged: (v) => setState(() => _maritalStatus = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _ptkpStatus,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge),
                        labelText: 'Status PTKP',
                      ),
                      items: _ptkpOptions
                          .map((p) => _buildDropdownItem(p))
                          .toList(),
                      onChanged: (v) => setState(() => _ptkpStatus = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Finance & Family
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Keuangan & Kontak',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nikCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.credit_card),
                        labelText: 'NIK (KTP)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _npwpCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        labelText: 'NPWP',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bankAccCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.account_balance),
                              labelText: 'No. Rekening (Mandiri)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bankAccNameCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: 'Nama Pemilik Rekening',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fatherNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Ayah'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motherNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Ibu'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _spouseNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Suami/Istri (jika ada)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _familyContactCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Keluarga / Wali',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Work info
              _sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pekerjaan & Pendidikan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Riwayat Pendidikan (Wajib diisi SD-SMK)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _eduSdCtrl,
                            decoration: const InputDecoration(labelText: 'SD'),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _eduSmpCtrl,
                            decoration: const InputDecoration(labelText: 'SMP'),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _eduSmkCtrl,
                            decoration: const InputDecoration(
                              labelText: 'SMA/SMK',
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Wajib' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pendidikan Tinggi (Opsional)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _eduS1Ctrl,
                            decoration: const InputDecoration(labelText: 'S1'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _eduS2Ctrl,
                            decoration: const InputDecoration(labelText: 'S2'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _eduS3Ctrl,
                            decoration: const InputDecoration(labelText: 'S3'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),

                    // Division Dropdown
                    _isLoadingDivisions
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedDivisionId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.business),
                              labelText: 'Divisi',
                            ),
                            items: _divisions.map((div) {
                              return DropdownMenuItem<int>(
                                value: div['id'] as int,
                                child: Text(
                                  div['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDivisionId = val;
                                _selectedJobPositionId = null; // Reset position
                                _jobPositions = [];

                                // Update controller text
                                final selectedDiv = _divisions.firstWhere(
                                  (d) => d['id'] == val,
                                  orElse: () => {},
                                );
                                if (selectedDiv.isNotEmpty) {
                                  _departmentCtrl.text = selectedDiv['name'];
                                  _department = selectedDiv['name'];
                                }
                              });
                              _fetchJobPositions(val);
                            },
                            validator: (v) =>
                                v == null ? 'Wajib pilih divisi' : null,
                          ),

                    const SizedBox(height: 12),

                    // Job Position Dropdown
                    _isLoadingJobPositions
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedJobPositionId,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.work),
                              labelText: 'Jabatan',
                            ),
                            items: _jobPositions.map((pos) {
                              return DropdownMenuItem<int>(
                                value: pos['id'] as int,
                                child: Text(
                                  pos['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedDivisionId == null
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedJobPositionId = val;

                                      // Update controller text
                                      final selectedPos = _jobPositions
                                          .firstWhere(
                                            (p) => p['id'] == val,
                                            orElse: () => {},
                                          );
                                      if (selectedPos.isNotEmpty) {
                                        _positionCtrl.text =
                                            selectedPos['name'];
                                        _position = selectedPos['name'];
                                      }
                                    });
                                  },
                            validator: (v) =>
                                v == null ? 'Wajib pilih jabatan' : null,
                          ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickJoinDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.date_range),
                          labelText: 'Tanggal Bergabung',
                          helperText: _joinDate == null
                              ? 'Setelah disimpan, hanya dapat diubah 1 kali.'
                              : (_joinDateEditCount >= 1
                                    ? 'Status: Terkunci (Maksimal perubahan tercapai)'
                                    : 'Dapat diubah 1 kali lagi.'),
                          helperStyle: TextStyle(
                            color:
                                (_joinDate != null && _joinDateEditCount >= 1)
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          _joinDate == null
                              ? '-'
                              : DateFormat.yMMMMd('id_ID').format(_joinDate!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: _supervisorNameCtrl,
                          focusNode: _supervisorFocusNode,
                          optionsBuilder:
                              (TextEditingValue textEditingValue) async {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<
                                    Map<String, dynamic>
                                  >.empty();
                                }
                                return await _employeeService.searchEmployees(
                                  textEditingValue.text,
                                );
                              },
                          displayStringForOption: (option) =>
                              option['full_name'] ?? '',
                          onSelected: (option) {
                            setState(() {
                              _supervisorPositionCtrl.text =
                                  option['position'] ?? '';
                              _supervisorId = option['id']; // Capture ID
                            });
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: 200,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final option = options.elementAt(
                                            index,
                                          );
                                          return ListTile(
                                            title: Text(
                                              option['full_name'] ?? '',
                                            ),
                                            subtitle: Text(
                                              option['position'] ?? '-',
                                            ),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                  ),
                                ),
                              ),
                            );
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller:
                                      controller, // Uses _supervisorNameCtrl internally
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Atasan Langsung',
                                    suffixIcon: Icon(Icons.search),
                                  ),
                                );
                              },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _supervisorPositionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jabatan Atasan Langsung',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
