import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/submission_card.dart';
import '../../services/request_service.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final data = await RequestService().getRequests();
      // data is List<dynamic> from the service
      if (mounted) {
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading submissions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSubmissions,
            color: AppTheme.colorEggplant,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      100 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: _buildFilteredList(),
                  ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilteredList() {
    // 1. Filter based on selection
    final selectedFilter = _filters[_selectedFilterIndex];

    // Map API status to Filter labels if necessary, or just match strings
    // API Statuses: pending, approved, rejected
    // Filters: Semua, Menunggu, Disetujui, Ditolak

    final filtered = _submissions.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      if (selectedFilter == 'Semua') return true;
      if (selectedFilter == 'Menunggu' && status == 'pending') return true;
      if (selectedFilter == 'Disetujui' && status == 'approved') return true;
      if (selectedFilter == 'Ditolak' && status == 'rejected') return true;
      return false;
    }).toList();

    if (filtered.isEmpty) {
      return [
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Tidak ada pengajuan $selectedFilter',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    // Sort by created_at descending
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    for (var item in filtered) {
      widgets.add(
        SubmissionCard(
          title: _mapTypeToTitle(item['type']),
          date: _formatDateRange(item['start_date'], item['end_date']),
          status: _mapStatusToLabel(item['status']),
          icon: _mapTypeToIcon(item['type']),
          iconColor: _mapStatusToColor(item['status']),
          iconBgColor: _mapStatusToColor(item['status']).withValues(alpha: 0.1),
          detailLabel: item['reason'] ?? '-',
          onTap: () {
            // Show detail if needed
          },
        ),
      );
    }

    return widgets;
  }

  String _mapTypeToTitle(String? type) {
    if (type == 'leave') return 'Cuti';
    if (type == 'permit') return 'Izin';
    if (type == 'sick') return 'Sakit';
    if (type == 'reimbursement') return 'Reimbursement'; // If implemented
    return type?.toUpperCase() ?? 'PENGAJUAN';
  }

  IconData _mapTypeToIcon(String? type) {
    if (type == 'leave') return Icons.calendar_month;
    if (type == 'permit') return Icons.assignment_outlined;
    if (type == 'sick') return Icons.local_hospital_outlined;
    return Icons.description_outlined;
  }

  String _mapStatusToLabel(String? status) {
    status = status?.toLowerCase();
    if (status == 'approved') return 'Disetujui';
    if (status == 'rejected') return 'Ditolak';
    return 'Menunggu';
  }

  Color _mapStatusToColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'approved') return AppTheme.info; // Cyan/Blue
    if (status == 'rejected') return const Color(0xFFE11D48); // Red
    return const Color(0xFFF59E0B); // Orange/Pending
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null) return '-';
    if (end == null || start == end) return start;
    return '$start s/d $end';
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      color: Colors.white.withValues(
        alpha: 0.8,
      ), // Translucent like sticky header
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.textDark,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
              ],
              const Text(
                'Pengajuan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.colorCyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppTheme.colorEggplant),
              onPressed: () {
                Navigator.pushNamed(context, '/submission/menu');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = index == _selectedFilterIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.colorCyan,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
