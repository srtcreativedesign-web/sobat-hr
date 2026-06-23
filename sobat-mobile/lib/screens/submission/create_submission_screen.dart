import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert'; // Added for base64Encode
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import '../../l10n/app_localizations.dart';
import '../../services/request_service.dart';

class CreateSubmissionScreen extends StatefulWidget {
  final String type; // 'Cuti', 'Sakit', 'Lembur', 'Reimbursement', etc.

  const CreateSubmissionScreen({super.key, required this.type});

  @override
  State<CreateSubmissionScreen> createState() => _CreateSubmissionScreenState();
}

class _CreateSubmissionScreenState extends State<CreateSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(); // Reuse for "Estimasi Harga"
  final _brandCtrl = TextEditingController(); // New: Merek
  final _specCtrl = TextEditingController(); // New: Spesifikasi
  final _titleCtrl =
      TextEditingController(); // New: Judul Pengajuan (Reimbursement)
  final _destinationCtrl = TextEditingController(); // New: Tujuan (Business Trip)
  final _vehiclePlateCtrl = TextEditingController(); // New: No Polisi (Izin Keluar)
  String _permitType = 'dinas'; // New: Keperluan (Izin Keluar)

  bool _isUrgent = false; // New: Urgent/Tidak
  File? _selectedFile; // Renamed from _selectedImage to allow PDF
  String? _fileExtension;
  final ImagePicker _picker = ImagePicker();

  // Singleton Signature Controller
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppTheme.textDark,
    exportBackgroundColor: Colors.transparent,
  );

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _leaveBalance = 0;
  bool _isEligible = true;
  bool _isLoading = false;
  String? _ineligibilityMessage;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'Cuti') {
      _loadLeaveData();
    }
  }

  Future<void> _loadLeaveData() async {
    setState(() => _isLoading = true);
    try {
      final data = await RequestService().getLeaveBalance();
      if (mounted) {
        setState(() {
          _leaveBalance = data['balance'] ?? 0;
          _isEligible = data['eligible'] ?? false;
          _ineligibilityMessage = data['message'];
          _isLoading = false;
        });

        if (!_isEligible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showIneligibilityDialog();
          });
        }
      }
    } catch (e) {
      // Error handled by AppErrorHandler in service
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Existing Type Config) ...
  Map<String, dynamic> get _typeConfig {
    switch (widget.type) {
      case 'Cuti':
        return {
          'icon': Icons.calendar_month,
          'color': const Color(0xFFEA580C),
          'bgColor': const Color(0xFFFFF7ED),
          'desc': AppLocalizations.of(context)!.cutiDesc,
          'quota': _isLoading
              ? AppLocalizations.of(context)!.loading
              : (_isEligible
                    ? AppLocalizations.of(context)!.sisaCutiLabel(_leaveBalance.toString())
                    : AppLocalizations.of(context)!.notEligible),
        };
      case 'Sakit':
        return {
          'icon': Icons.thermostat,
          'color': const Color(0xFFE11D48),
          'bgColor': const Color(0xFFFFF1F2),
          'desc': AppLocalizations.of(context)!.sakitDesc,
          'quota': null,
        };
      case 'Reimbursement':
        return {
          'icon': Icons.attach_money,
          'color': const Color(0xFF059669),
          'bgColor': const Color(0xFFD1FAE5),
          'desc': AppLocalizations.of(context)!.reimburseDesc,
          'quota': AppLocalizations.of(context)!.reimbursementLimit,
        };
      case 'Lembur':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFF2563EB), // Blue 600
          'bgColor': const Color(0xFFEFF6FF), // Blue 50
          'desc': AppLocalizations.of(context)!.lemburDesc,
          'quota': null,
        };
      case 'Perjalanan Dinas':
        return {
          'icon': Icons.flight_takeoff,
          'color': const Color(0xFF4F46E5), // Indigo 600
          'bgColor': const Color(0xFFEEF2FF), // Indigo 50
          'desc': AppLocalizations.of(context)!.dinasDesc,
          'quota': null,
        };
      case 'Pengajuan Aset':
        return {
          'icon': Icons.devices,
          'color': const Color(0xFF7C3AED),
          'bgColor': const Color(0xFFEDE9FE),
          'desc': AppLocalizations.of(context)!.asetDesc,
          'quota': null,
        };
      case 'Resign':
        return {
          'icon': Icons.logout,
          'color': const Color(0xFFDC2626), // Red 600
          'bgColor': const Color(0xFFFEF2F2), // Red 50
          'desc': AppLocalizations.of(context)!.resignDesc,
          'quota': null,
        };
      default:
        return {
          'icon': Icons.description,
          'color': Colors.grey,
          'bgColor': Colors.grey.shade100,
          'desc': AppLocalizations.of(context)!.featureComingSoon,
          'quota': null,
        };
    }
  }

  String _translateType(String type) {
    switch (type) {
      case 'Cuti':
        return AppLocalizations.of(context)!.leave;
      case 'Sakit':
        return AppLocalizations.of(context)!.sick;
      case 'Lembur':
        return AppLocalizations.of(context)!.overtime;
      case 'Reimbursement':
        return AppLocalizations.of(context)!.reimbursement;
      case 'Perjalanan Dinas':
        return AppLocalizations.of(context)!.businessTrip;
      case 'Pengajuan Aset':
        return AppLocalizations.of(context)!.assetLabel;
      case 'Resign':
        return AppLocalizations.of(context)!.resignationLabel;
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    _brandCtrl.dispose();
    _specCtrl.dispose();
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig;

    return Scaffold(
      backgroundColor: config['bgColor'], // Colored background at top
      appBar: AppBar(
        title: const Text(''), // Empty Layout for Custom Header
        leading: BackButton(color: AppTheme.textDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.type == 'Lembur')
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/submission/overtime-history');
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text(
                  'Riwayat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorCyan,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          if (config['quota'] != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                config['quota'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: config['color'],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (config['color'] as Color).withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(config['icon'], color: config['color'], size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.createSubmission,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        _translateType(widget.type),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config['desc'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Form Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.type == 'Cuti' ||
                          widget.type == 'Sakit' ||
                          widget.type == 'Perjalanan Dinas') ...[
                        _buildDateRangePicker(),
                        if (widget.type == 'Perjalanan Dinas') ...[
                          const SizedBox(height: 20),
                          _buildTextInput(
                            _destinationCtrl,
                            'Tujuan',
                            'Masukkan kota atau tempat tujuan dinas',
                            maxLines: 1,
                          ),
                        ],
                        if (widget.type == 'Sakit') ...[
                          const SizedBox(height: 20),
                          _buildUploadButton(),
                        ],
                      ] else if (widget.type == 'Lembur') ...[
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildTimeRangePicker(),
                        const SizedBox(height: 20),
                        _buildUploadButton(label: AppLocalizations.of(context)!.uploadProofLabel),
                      ] else if (widget.type == 'Reimbursement') ...[
                        _buildTextInput(
                          _titleCtrl,
                          AppLocalizations.of(context)!.submissionTypeLabel,
                          AppLocalizations.of(context)!.reimbursementTitleHint,
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 20),
                        _buildUploadButton(),
                      ] else if (widget.type == 'Pengajuan Aset') ...[
                        _buildTextInput(
                          _brandCtrl,
                          AppLocalizations.of(context)!.brandOrMake,
                          AppLocalizations.of(context)!.brandHint,
                        ),
                        const SizedBox(height: 20),
                        _buildTextInput(
                          _specCtrl,
                          AppLocalizations.of(context)!.specification,
                          AppLocalizations.of(context)!.specHint,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        _buildAmountField(label: AppLocalizations.of(context)!.nominalLabel),
                        const SizedBox(height: 20),
                        _buildUrgencySwitch(),
                        const SizedBox(height: 20),
                        _buildUploadButton(label: AppLocalizations.of(context)!.photoItemOptional),
                      ] else if (widget.type == 'Resign') ...[
                        _buildLabel(AppLocalizations.of(context)!.lastWorkingDate),
                        _buildClickableInput(
                          icon: Icons.calendar_month,
                          value: _startDate != null
                              ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US').format(_startDate!)
                              : AppLocalizations.of(context)!.selectDate,
                          isPlaceholder: _startDate == null,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _startDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildUploadButton(label: AppLocalizations.of(context)!.resignationLabel),
                      ] else if (widget.type == 'Izin Keluar') ...[
                        _buildLabel('Keperluan'),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _permitType = 'dinas'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(_permitType == 'dinas' ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppTheme.colorPrimary, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Dinas', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _permitType = 'pribadi'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(_permitType == 'pribadi' ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppTheme.colorPrimary, size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Pribadi', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextInput(
                          _destinationCtrl,
                          'Tujuan',
                          'Misal: Bandara Soekarno Hatta',
                        ),
                        const SizedBox(height: 20),
                        _buildTextInput(
                          _vehiclePlateCtrl,
                          'No Polisi Kendaraan (Opsional)',
                          'Misal: B 1234 ABC',
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Tanggal Keluar'),
                        _buildClickableInput(
                          icon: Icons.calendar_today,
                          value: _startDate != null
                              ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US').format(_startDate!)
                              : 'Pilih Tanggal',
                          isPlaceholder: _startDate == null,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) setState(() => _startDate = picked);
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Jam Keluar'),
                                  _buildClickableInput(
                                    icon: Icons.access_time,
                                    value: _startTime?.format(context) ?? 'Pilih Waktu',
                                    isPlaceholder: _startTime == null,
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) setState(() => _startTime = picked);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Jam Selesai'),
                                  _buildClickableInput(
                                    icon: Icons.access_time,
                                    value: _endTime?.format(context) ?? 'Selesai',
                                    isPlaceholder: _endTime == null,
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) setState(() => _endTime = picked);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildReasonField(
                        label: widget.type == 'Pengajuan Aset'
                            ? AppLocalizations.of(context)!.purposeLabel
                            : null,
                      ),

                      const SizedBox(height: 20),
                      _buildSignaturePad(),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.textDark, // Dark button for contrast
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.submit,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Safe area
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.selectDate),
        Row(
          children: [
            Expanded(
              child: _buildClickableInput(
                icon: Icons.calendar_today,
                value: _startDate != null
                    ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US').format(_startDate!)
                    : AppLocalizations.of(context)!.startOvertime,
                isPlaceholder: _startDate == null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppTheme.textLight,
              ),
            ),
            Expanded(
              child: _buildClickableInput(
                icon: Icons.event,
                value: _endDate != null
                    ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US').format(_endDate!)
                    : AppLocalizations.of(context)!.endOvertime,
                isPlaceholder: _endDate == null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.date),
        _buildClickableInput(
          icon: Icons.calendar_month,
          value: _startDate != null
              ? DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US').format(_startDate!)
              : AppLocalizations.of(context)!.selectDate,
          isPlaceholder: _startDate == null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
        ),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.overtimeHours),
        Row(
          children: [
            Expanded(
              child: _buildClickableInput(
                icon: Icons.access_time,
                value: _startTime?.format(context) ?? AppLocalizations.of(context)!.startOvertime,
                isPlaceholder: _startTime == null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClickableInput({
    required IconData icon,
    required String value,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPlaceholder ? AppTheme.textLight : AppTheme.textDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isPlaceholder ? AppTheme.textLight : AppTheme.textDark,
                  fontWeight: isPlaceholder
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField({String? label}) {
    final displayLabel = label ?? AppLocalizations.of(context)!.nominalLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(displayLabel),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: 'Rp ',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
        ),
      ],
    );
  }

  Widget _buildUploadButton({String? label}) {
    final displayLabel = label ?? AppLocalizations.of(context)!.uploadProofLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          widget.type == 'Sakit'
              ? AppLocalizations.of(context)!.doctorCertificate
              : (widget.type == 'Pengajuan Aset'
                    ? AppLocalizations.of(context)!.photoItemOptional
                    : displayLabel),
        ),
        if (_selectedFile != null)
          Stack(
            children: [
              if (_fileExtension == 'pdf')
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedFile!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFile = null;
                      _fileExtension = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ),
              ),
            ],
          )
        else
          DottedBorderButton(
            label: widget.type == 'Sakit'
                ? AppLocalizations.of(context)!.photoDoctorCertificate
                : AppLocalizations.of(context)!.uploadProofLabel,
            onTap: _showImageSourceModal,
          ),
      ],
    );
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.photoSourceTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: AppLocalizations.of(context)!.camera,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: AppLocalizations.of(context)!.gallery,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (widget.type == 'Resign')
                  _buildSourceOption(
                    icon: Icons.picture_as_pdf,
                    label: AppLocalizations.of(context)!.document,
                    onTap: () => _pickFile(),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.colorCyan),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 30, // Aggressive compression to save bandwidth
      );
      if (picked != null) {
        setState(() {
          _selectedFile = File(picked.path);
          _fileExtension = 'jpg'; // Assume image from picker
        });
      }
    } catch (e) {
      // Error handled by AppErrorHandler in service
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.photoUploadError(e.toString()))));
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String ext = result.files.single.extension?.toLowerCase() ?? '';
        setState(() {
          _selectedFile = file;
          _fileExtension = ext;
        });
      }
    } catch (e) {
      // Error handled by AppErrorHandler in service
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fileUploadError(e.toString()))));
    }
  }

  Widget _buildReasonField({String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          label ??
              (widget.type == 'Reimbursement' || widget.type == 'Sakit'
                  ? AppLocalizations.of(context)!.description
                  : AppLocalizations.of(context)!.reason),
        ),
        TextFormField(
          controller: _reasonCtrl,
          maxLines: 4,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.writeSubmissionDetail,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
        ),
      ],
    );
  }

  Widget _buildSignaturePad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.signatureDigital),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Signature(
                controller: _signatureController,
                height: 150,
                width: double.infinity,
                backgroundColor: Colors.transparent,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _signatureController.clear(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
        ),
      ],
    );
  }

  Widget _buildUrgencySwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isUrgent ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isUrgent ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.priority_high,
            color: _isUrgent ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.urgentCheckbox,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isUrgent ? Colors.red.shade700 : AppTheme.textDark,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.urgentDesc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _isUrgent,
            onChanged: (val) => setState(() => _isUrgent = val),
            activeThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }

  void _showIneligibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.ineligibilityTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _ineligibilityMessage ?? AppLocalizations.of(context)!.ineligibilityReasonDefault,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)!.iUnderstand),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.type == 'Sakit' && _selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseUploadDoctorCert),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSignSubmission),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (widget.type == 'Cuti' && !_isEligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ineligibilityMessage ?? AppLocalizations.of(context)!.ineligibilityCantSubmit,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Map widget.type to API type field
        String apiType = 'leave';
        switch (widget.type) {
          case 'Cuti':
            apiType = 'leave';
            break;
          case 'Sakit':
            apiType = 'sick_leave';
            break;
          case 'Lembur':
            apiType = 'overtime';
            break;
          case 'Reimbursement':
            apiType = 'reimbursement';
            break;
          case 'Pengajuan Aset':
            apiType = 'asset';
            break;
          case 'Perjalanan Dinas':
            apiType = 'business_trip';
            break;
          case 'Resign':
            apiType = 'resignation';
            break;
          case 'Izin Keluar':
            apiType = 'exit_permit';
            break;

          default:
        }

        final Map<String, dynamic> data = {
          'type': apiType,
          'title': (widget.type == 'Reimbursement')
              ? _titleCtrl.text
              : widget.type,
          'description': _reasonCtrl.text,
          'start_date': _startDate?.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'amount': _amountCtrl.text.isNotEmpty
              ? double.tryParse(
                  _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                )
              : null,
        };

        // Add Specific Fields
        if (apiType == 'overtime' && _startTime != null) {
          data['start_time'] =
              '${_startTime!.hour.toString().padLeft(2, "0")}:${_startTime!.minute.toString().padLeft(2, "0")}';
        }

        if (apiType == 'business_trip') {
          data['destination'] = _destinationCtrl.text;
        }

        if (apiType == 'asset') {
          data['brand'] = _brandCtrl.text;
          data['specification'] = _specCtrl.text;
          data['specification'] = _specCtrl.text;
          data['is_urgent'] = _isUrgent;
        }

        if (apiType == 'resignation') {
          // Last Working Date is mapped to start_date in base object for now, or specific field
          // Based on Plan, backend expects 'last_working_date'.
          // Mobile maps _startDate to 'start_date'.
          // RequestController stores 'start_date' in request table, BUT for resignation logic
          // it uses: 'last_working_date' => $request->last_working_date
          // So I need to send 'last_working_date'.
          data['last_working_date'] = _startDate?.toIso8601String();
        }

        if (apiType == 'exit_permit') {
          data['permit_type'] = _permitType;
          data['destination'] = _destinationCtrl.text;
          data['vehicle_plate'] = _vehiclePlateCtrl.text;
          if (_startTime != null) {
            data['start_time'] = '${_startTime!.hour.toString().padLeft(2, "0")}:${_startTime!.minute.toString().padLeft(2, "0")}';
          }
          if (_endTime != null) {
            data['end_time'] = '${_endTime!.hour.toString().padLeft(2, "0")}:${_endTime!.minute.toString().padLeft(2, "0")}';
          }
          final sigBytes = await _signatureController.toPngBytes();
          if (sigBytes != null) {
            data['signature'] = 'data:image/png;base64,${base64Encode(sigBytes)}';
          }
        }

        // Process Attachments (Image/PDF)
        if (_selectedFile != null) {
          final bytes = await _selectedFile!.readAsBytes();
          final base64String = base64Encode(bytes);

          String mimeType = 'image/jpeg';
          if (_fileExtension == 'pdf') {
            mimeType = 'application/pdf';
          }

          List<String> attachmentsList = [
            'data:$mimeType;base64,$base64String',
          ];
          data['attachments'] = jsonEncode(attachmentsList);
        }

        // Process Signature
        final signatureBytes = await _signatureController.toPngBytes();
        if (signatureBytes != null) {
          final base64Signature = base64Encode(signatureBytes);
          data['signature'] = 'data:image/png;base64,$base64Signature';
          // Note: Verify if backend accepts 'signature'. If not, it will just be ignored.
        }

        await RequestService().createRequest(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.submissionSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
      // Error handled by AppErrorHandler in service
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.submissionFail(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

class DottedBorderButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DottedBorderButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.none, // Removed solid border for clean look
          ),
          color: Colors.grey.shade100,
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
