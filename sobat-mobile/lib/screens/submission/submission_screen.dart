import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/submission_card.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              100 + MediaQuery.of(context).padding.bottom,
            ),
            children: _buildFilteredList(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilteredList() {
    // 1. Define ALL mock data
    final allSubmissions = [
      {
        'title': 'Cuti Tahunan',
        'date': '12 Jan 2026 - 14 Jan 2026',
        'status': 'Menunggu',
        'icon': Icons.calendar_month,
        'iconColor': const Color(0xFFEA580C),
        'iconBgColor': const Color(0xFFFFF7ED),
        'detailLabel': '3 Hari kerja',
        'section': 'Terbaru',
      },
      {
        'title': 'Reimbursement Medis',
        'date': '10 Des 2025',
        'status': 'Disetujui',
        'icon': Icons.medical_services,
        'iconColor': AppTheme.info,
        'iconBgColor': AppTheme.info.withValues(alpha: 0.1),
        'detailLabel': 'Rp 450.000',
        'section': 'Terbaru',
      },
      {
        'title': 'Cuti Sakit',
        'date': '01 Nov 2025',
        'status': 'Ditolak',
        'icon': Icons.thermostat,
        'iconColor': const Color(0xFFE11D48),
        'iconBgColor': const Color(0xFFFFF1F2),
        'detailLabel': '1 Hari • Lampiran kurang',
        'section': '2025',
      },
      {
        'title': 'Perjalanan Dinas',
        'date': '15 Okt 2025',
        'status': 'Disetujui',
        'icon': Icons.flight_takeoff,
        'iconColor': AppTheme.info,
        'iconBgColor': AppTheme.info.withValues(alpha: 0.1),
        'detailLabel': 'Jakarta - Bandung',
        'section': '2025',
      },
      {
        'title': 'Lembur',
        'date': '02 Okt 2025',
        'status': 'Disetujui',
        'icon': Icons.schedule,
        'iconColor': AppTheme.info,
        'iconBgColor': AppTheme.info.withValues(alpha: 0.1),
        'detailLabel': '4 Jam',
        'section': '2025',
      },
    ];

    // 2. Filter based on selection
    final selectedFilter = _filters[_selectedFilterIndex];
    final filtered = selectedFilter == 'Semua'
        ? allSubmissions
        : allSubmissions
              .where((item) => item['status'] == selectedFilter)
              .toList();

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

    // 3. Group by Section if "Semua" or just list them
    // For simplicity, we keep sections only if "Semua" is selected,
    // or we can allow sections to appear if items match.
    // Let's preserve sections for better UX.

    List<Widget> widgets = [];
    String? currentSection;

    for (var item in filtered) {
      // Add Section Title if changed
      if (item['section'] != currentSection) {
        currentSection = item['section'] as String;
        widgets.add(_buildSectionTitle(currentSection));
      }

      // Add Card
      widgets.add(
        SubmissionCard(
          title: item['title'] as String,
          date: item['date'] as String,
          status: item['status'] as String,
          icon: item['icon'] as IconData,
          iconColor: item['iconColor'] as Color,
          iconBgColor: item['iconBgColor'] as Color,
          detailLabel: item['detailLabel'] as String,
          onTap: () {},
        ),
      );
    }

    return widgets;
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
          const Text(
            'Pengajuan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              letterSpacing: -1,
            ),
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
