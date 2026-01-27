import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../services/request_service.dart'; // Added

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

  bool _isUrgent = false; // New: Urgent/Tidak
  File? _selectedImage;
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _ineligibilityMessage ?? 'Anda tidak memenuhi syarat cuti.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading leave balance: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Existing Type Config) ...
  Map<String, dynamic> get _typeConfig {
    // Reusing existing type config logic (omitted for brevity in replacement, but I must be careful not to delete it if I replacing the whole block.
    // Wait, I should not replace the whole class if I can avoid it.
    // Actually, let's just replace the relevant parts.
    // I'll start by adding imports and variables using replace_file_content carefully.
    // But wait, the previous `replace_file_content` instruction says I should replace the whole file content if I am making multiple edits? No, "Use this tool ONLY when you are making a SINGLE CONTIGUOUS block of edits".
    // I need to make multiple edits: Imports, Class Fields, Dispose, Build Method (adding the widget), and Helper Method.
    // I should use `multi_replace_file_content`.
    switch (widget.type) {
      case 'Cuti':
        return {
          'icon': Icons.calendar_month,
          'color': const Color(0xFFEA580C),
          'bgColor': const Color(0xFFFFF7ED),
          'desc': 'Ajukan cuti tahunan atau cuti khusus.',
          'quota': _isLoading
              ? 'Memuat...'
              : (_isEligible
                    ? 'Sisa Cuti: $_leaveBalance Hari'
                    : 'Tidak Eligible'),
        };
      case 'Sakit':
        return {
          'icon': Icons.thermostat,
          'color': const Color(0xFFE11D48),
          'bgColor': const Color(0xFFFFF1F2),
          'desc': 'Upload surat dokter untuk cuti sakit.',
          'quota': null,
        };
      case 'Reimbursement':
        return {
          'icon': Icons.attach_money,
          'color': const Color(0xFF059669),
          'bgColor': const Color(0xFFD1FAE5),
          'desc': 'Klaim biaya medis, kacamata, dll.',
          'quota': 'Limit: Rp 5.000.000',
        };
      case 'Lembur':
        return {
          'icon': Icons.schedule,
          'color': const Color(0xFF2563EB), // Blue 600
          'bgColor': const Color(0xFFEFF6FF), // Blue 50
          'desc': 'Catat jam lembur untuk persetujuan.',
          'quota': null,
        };
      case 'Perjalanan Dinas':
        return {
          'icon': Icons.flight_takeoff,
          'color': const Color(0xFF4F46E5), // Indigo 600
          'bgColor': const Color(0xFFEEF2FF), // Indigo 50
          'desc': 'Pengajuan perjalanan bisnis luar kota.',
          'quota': null,
        };
      case 'Pengajuan Aset':
        return {
          'icon': Icons.devices,
          'color': const Color(0xFF7C3AED),
          'bgColor': const Color(0xFFEDE9FE),
          'desc': 'Ajukan pengadaan barang atau aset kantor.',
          'quota': null,
        };
      default:
        return {
          'icon': Icons.description,
          'color': Colors.grey,
          'bgColor': Colors.grey.shade100,
          'desc': 'Formulir pengajuan umum.',
          'quota': null,
        };
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    _brandCtrl.dispose();
    _specCtrl.dispose();
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
                        'Buat Pengajuan',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        widget.type,
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
                        if (widget.type == 'Sakit') ...[
                          const SizedBox(height: 20),
                          _buildUploadButton(),
                        ],
                      ] else if (widget.type == 'Lembur') ...[
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildTimeRangePicker(),
                      ] else if (widget.type == 'Reimbursement') ...[
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 20),
                        _buildUploadButton(),
                      ] else if (widget.type == 'Pengajuan Aset') ...[
                        _buildTextInput(
                          _brandCtrl,
                          'Merek / Brand',
                          'Contoh: Macbook, Dell, Logitech',
                        ),
                        const SizedBox(height: 20),
                        _buildTextInput(
                          _specCtrl,
                          'Spesifikasi',
                          'Jelaskan spesifikasi yang dibutuhkan...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        _buildAmountField(label: 'Estimasi Harga (Rp)'),
                        const SizedBox(height: 20),
                        _buildUrgencySwitch(),
                        const SizedBox(height: 20),
                        _buildUploadButton(label: 'Foto Contoh Barang'),
                      ],

                      const SizedBox(height: 20),
                      _buildReasonField(
                        label: widget.type == 'Pengajuan Aset'
                            ? 'Kebutuhan (Untuk Apa)'
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
                          child: const Text(
                            'Kirim Pengajuan',
                            style: TextStyle(
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
        _buildLabel('Pilih Tanggal'),
        Row(
          children: [
            Expanded(
              child: _buildClickableInput(
                icon: Icons.calendar_today,
                value: _startDate != null
                    ? DateFormat('dd MMM yyyy').format(_startDate!)
                    : 'Mulai',
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
                    ? DateFormat('dd MMM yyyy').format(_endDate!)
                    : 'Selesai',
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
        _buildLabel('Tanggal'),
        _buildClickableInput(
          icon: Icons.calendar_month,
          value: _startDate != null
              ? DateFormat('dd MMM yyyy').format(_startDate!)
              : 'Pilih Tanggal',
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
        _buildLabel('Jam Lembur'),
        Row(
          children: [
            Expanded(
              child: _buildClickableInput(
                icon: Icons.access_time,
                value: _startTime?.format(context) ?? 'Mulai',
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.horizontal_rule,
                size: 20,
                color: AppTheme.textLight,
              ),
            ),
            Expanded(
              child: _buildClickableInput(
                icon: Icons.access_time_filled,
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

  Widget _buildAmountField({String label = 'Nominal (Rp)'}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
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
          validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildUploadButton({String label = 'Upload Bukti / Struk'}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          widget.type == 'Sakit'
              ? 'Surat Dokter'
              : (widget.type == 'Pengajuan Aset'
                    ? 'Foto Barang (Opsional)'
                    : label),
        ),
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
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
                      _selectedImage = null;
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
                ? 'Foto Surat Dokter'
                : 'Upload Bukti',
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
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
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
        imageQuality: 50, // Optimize image size
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Widget _buildReasonField({String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          label ?? (widget.type == 'Reimbursement' ? 'Keterangan' : 'Alasan'),
        ),
        TextFormField(
          controller: _reasonCtrl,
          maxLines: 4,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tuliskan detail pengajuan di sini...',
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
          validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildSignaturePad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanda Tangan Digital'),
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
          validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
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
                  'Urgent / Mendesak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isUrgent ? Colors.red.shade700 : AppTheme.textDark,
                  ),
                ),
                Text(
                  'Centang jika barang dibutuhkan segera',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _isUrgent,
            onChanged: (val) => setState(() => _isUrgent = val),
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap tanda tangani pengajuan sebelum mengirim.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (widget.type == 'Cuti' && !_isEligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _ineligibilityMessage ?? 'Anda tidak dapat mengajukan cuti.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Prepare Data
      // Map widget.type to API type field
      String apiType = 'leave';
      if (widget.type == 'Sakit')
        apiType = 'leave'; // Sick is also leave type usually, or separate?
      // User requested "Cuti", logic applies to "Cuti".
      // Let's assume 'Cuti' -> 'leave', 'Sakit' -> 'leave' (with attachment?), 'Lembur' -> 'overtime', 'Reimbursement' -> 'reimbursement', 'Pengajuan Aset' -> 'reimbursement' (asset?)
      // For now let's map simply:
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
        default:
          apiType = 'reimbursement';
          break;
      }

      final Map<String, dynamic> data = {
        'type': apiType,
        'title': widget.type,
        'description': _reasonCtrl.text,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        // For Reimbursement/Asset use amount
        'amount': _amountCtrl.text.isNotEmpty
            ? double.tryParse(
                _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
              )
            : null,
      };

      // Add Specific Fields
      if (apiType == 'overtime' && _startTime != null && _endTime != null) {
        data['start_time'] =
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        data['end_time'] =
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
        // Calculate duration in minutes
        final start = DateTime(
          2024,
          1,
          1,
          _startTime!.hour,
          _startTime!.minute,
        );
        var end = DateTime(2024, 1, 1, _endTime!.hour, _endTime!.minute);
        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 1)); // Cross midnight
        }
        data['duration'] = end.difference(start).inMinutes;
      }

      if (apiType == 'asset') {
        data['brand'] = _brandCtrl.text;
        data['specification'] = _specCtrl.text;
        data['is_urgent'] = _isUrgent;
      }

      try {
        // Upload image if exists? Implementation complexity.
        // Current RequestService createRequest only accepts Map.
        // For strict MVP, we might skip file upload or add it later.

        await RequestService().createRequest(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan berhasil dikirim'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('❌ Submission Failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
