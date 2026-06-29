import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'submission_detail_screen.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/organisms/submission_card.dart';
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

  String _selectedType = 'all';

  List<Map<String, String>> _getTypeFilters(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      {'value': 'all', 'label': loc.allLabel},
      {'value': 'leave', 'label': loc.leave},
      {'value': 'sick', 'label': loc.sick},
      {'value': 'overtime', 'label': loc.overtime},
      {'value': 'business_trip', 'label': loc.businessTrip},
      {'value': 'reimbursement', 'label': loc.reimbursement},
    ];
  }

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
      // Error handled by AppErrorHandler in service
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadData} $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTypeFilters(),
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
                      8,
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

  Widget _buildTypeFilters() {
    final types = _getTypeFilters(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedType == type['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type['value']!);
                }
              },
              selectedColor: AppTheme.colorCyan.withValues(alpha: 0.1),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppTheme.colorCyan : Colors.grey.shade200,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.colorCyan : AppTheme.textLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildFilteredList() {
    // 1. Filter based on selection
    final selectedFilter = _filters[_selectedFilterIndex];

    final filtered = _submissions.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();

      // Category filter
      if (_selectedType != 'all') {
        if (_selectedType == 'sick' && (type == 'sick' || type == 'sick_leave')) {
          // Allow
        } else if (type != _selectedType) {
          return false;
        }
      }

      if (selectedFilter == 'Semua') return true;
      if (selectedFilter == 'Menunggu' && status == 'pending') return true;
      if (selectedFilter == 'Disetujui' && status == 'approved') return true;
      if (selectedFilter == 'Ditolak' && status == 'rejected') return true;
      return false;
    }).toList();

    final translatedFilters = [
      AppLocalizations.of(context)!.allLabel,
      AppLocalizations.of(context)!.pending,
      AppLocalizations.of(context)!.approved,
      AppLocalizations.of(context)!.rejected,
    ];
    final translatedFilterLabel = translatedFilters[_selectedFilterIndex];

    if (filtered.isEmpty) {
      return [
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noSubmissionWithStatus(translatedFilterLabel),
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
          title: _mapTypeToTitle(context, item['type']),
          date: _formatDateRange(
            context,
            item['start_date'],
            item['end_date'],
            item['created_at'],
          ),
          status: _mapStatusToLabel(context, item['status']),
          iconWidget: _mapTypeToIcon(item['type']),
          iconColor: _mapStatusToColor(item['status']),
          iconBgColor: _mapStatusToColor(item['status']).withValues(alpha: 0.1),
          detailLabel: item['reason'] ?? '-',
          onTap: () {
            if (item['type'] == 'overtime') {
              Navigator.pushNamed(context, '/submission/overtime-history');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmissionDetailScreen(submission: item),
                ),
              );
            }
          },
        ),
      );
    }

    return widgets;
  }

  String _mapTypeToTitle(BuildContext context, String? type) {
    if (type == 'leave') return AppLocalizations.of(context)!.leave;
    if (type == 'permit') return AppLocalizations.of(context)!.permitLabel;
    if (type == 'sick' || type == 'sick_leave') return AppLocalizations.of(context)!.sick;
    if (type == 'reimbursement') return AppLocalizations.of(context)!.reimbursement;
    if (type == 'business_trip') return AppLocalizations.of(context)!.businessTrip;
    if (type == 'overtime') return AppLocalizations.of(context)!.overtime;
    if (type == 'asset') return AppLocalizations.of(context)!.assetLabel;
    if (type == 'resignation') return AppLocalizations.of(context)!.resignationLabel;
    return type?.replaceAll('_', ' ').toUpperCase() ?? AppLocalizations.of(context)!.submissions.toUpperCase();
  }

  Widget _mapTypeToIcon(String? type) {
    if (type == 'sick' || type == 'sick_leave') {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset('assets/icons/sick.png', fit: BoxFit.contain),
      );
    }
    if (type == 'leave') return const Icon(Icons.calendar_month, size: 24);
    if (type == 'permit') return const Icon(Icons.assignment_outlined, size: 24);
    if (type == 'business_trip') return const Icon(Icons.flight_takeoff, size: 24);
    if (type == 'reimbursement') return const Icon(Icons.attach_money, size: 24);
    if (type == 'overtime') return const Icon(Icons.schedule, size: 24);
    if (type == 'asset') return const Icon(Icons.devices, size: 24);
    if (type == 'resignation') return const Icon(Icons.logout, size: 24);
    return const Icon(Icons.description_outlined, size: 24);
  }

  String _mapStatusToLabel(BuildContext context, String? status) {
    status = status?.toLowerCase();
    if (status == 'approved') return AppLocalizations.of(context)!.approved;
    if (status == 'rejected') return AppLocalizations.of(context)!.rejected;
    return AppLocalizations.of(context)!.pending;
  }

  Color _mapStatusToColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'approved') return AppTheme.info; // Cyan/Blue
    if (status == 'rejected') return const Color(0xFFE11D48); // Red
    return const Color(0xFFF59E0B); // Orange/Pending
  }

  String _formatDateRange(BuildContext context, String? start, String? end, String? createdAt) {
    final localeName = Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    try {
      if (start == null) {
        if (createdAt != null) {
          final created = DateTime.parse(createdAt);
          return DateFormat('d MMM y', localeName).format(created);
        }
        return '-';
      }
      final startDate = DateTime.parse(start);
      final startStr = DateFormat('d MMM y', localeName).format(startDate);

      if (end == null || start == end) return startStr;

      final endDate = DateTime.parse(end);
      final endStr = DateFormat('d MMM y', localeName).format(endDate);

      return '$startStr ${AppLocalizations.of(context)!.dateRangeSeparator} $endStr';
    } catch (_) {
      return start ?? '-';
    }
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
              Text(
                AppLocalizations.of(context)!.submissions,
                style: const TextStyle(
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
                Navigator.pushNamed(context, '/submission/menu').then((_) {
                  _loadSubmissions();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final translatedFilters = [
      AppLocalizations.of(context)!.allLabel,
      AppLocalizations.of(context)!.pending,
      AppLocalizations.of(context)!.approved,
      AppLocalizations.of(context)!.rejected,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final index = entry.key;
          final label = translatedFilters[index];
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
}
