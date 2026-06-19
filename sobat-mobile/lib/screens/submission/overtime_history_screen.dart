import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/overtime_provider.dart';
import '../../l10n/app_localizations.dart';
import 'submission_detail_screen.dart';

class OvertimeHistoryScreen extends StatefulWidget {
  const OvertimeHistoryScreen({super.key});

  @override
  State<OvertimeHistoryScreen> createState() => _OvertimeHistoryScreenState();
}

class _OvertimeHistoryScreenState extends State<OvertimeHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Menunggu, 2: Disetujui
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final status = _selectedFilterIndex == 1
        ? 'pending'
        : _selectedFilterIndex == 2
            ? 'approved'
            : null;
    await context.read<OvertimeProvider>().fetchOvertimeHistory(
      status: status,
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.colorCyan,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filters = [
      loc.allLabel,
      loc.pending,
      loc.approved,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          loc.overtimeHistoryTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Consumer<OvertimeProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filters
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: List.generate(
                          filters.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filters[index]),
                              selected: _selectedFilterIndex == index,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedFilterIndex = index);
                                  _fetchData();
                                }
                              },
                              backgroundColor: Colors.grey.shade100,
                              selectedColor: AppTheme.colorCyan.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: _selectedFilterIndex == index
                                    ? AppTheme.colorCyan
                                    : Colors.grey.shade600,
                                fontWeight: _selectedFilterIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _selectedFilterIndex == index
                                      ? AppTheme.colorCyan
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('dd MMM yy', 'id_ID').format(_startDate!)} - ${DateFormat('dd MMM yy', 'id_ID').format(_endDate!)}'
                                    : loc.selectPeriod,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.colorCyan,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                          if (_startDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                                _fetchData();
                              },
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              tooltip: loc.clearPeriod,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Download Summary Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: Colors.white,
                child: ElevatedButton.icon(
                  onPressed: provider.isDownloading
                      ? null
                      : () async {
                          try {
                            final status = _selectedFilterIndex == 1
                                ? 'pending'
                                : _selectedFilterIndex == 2
                                    ? 'approved'
                                    : null;
                            await provider.downloadSummaryPdf(
                              status: status,
                              startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
                              endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: provider.isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    provider.isDownloading
                        ? loc.downloading
                        : loc.downloadPdfSummary,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchData,
                                  child: Text(loc.tryAgain),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: provider.overtimeHistory.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.5,
                                        child: Center(
                                          child: Text(
                                            loc.noSubmissionWithStatus(filters[_selectedFilterIndex]),
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(24),
                                    itemCount: provider.overtimeHistory.length,
                                    itemBuilder: (context, index) {
                                      final item = provider.overtimeHistory[index];
                                      return _buildOvertimeCard(context, item);
                                    },
                                  ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOvertimeCard(BuildContext context, Map<String, dynamic> item) {
    final loc = AppLocalizations.of(context)!;
    final localeName =
        Localizations.localeOf(context).languageCode == 'id' ? 'id_ID' : 'en_US';
    final status = item['status']?.toString().toLowerCase() ?? 'pending';

    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = AppTheme.colorCyan;
      statusLabel = loc.approved;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = loc.rejected;
    } else if (status == 'spl_open') {
      statusColor = Colors.green;
      statusLabel = 'LEMBUR BERJALAN';
    } else if (status == 'spl_approved') {
      statusColor = Colors.blue;
      statusLabel = 'MENUNGGU MULAI';
    } else if (status == 'pending_final') {
      statusColor = Colors.orange;
      statusLabel = 'MENUNGGU FINAL';
    } else {
      statusColor = Colors.orange;
      statusLabel = loc.pending;
    }

    String date = '-';
    if (item['start_date'] != null) {
      try {
        date = DateFormat('d MMM y', localeName).format(
          DateTime.parse(item['start_date']),
        );
      } catch (_) {
        date = item['start_date'];
      }
    }

    // Detail Time
    String timeInfo = '';
    if (item['overtime_detail'] != null) {
      final detail = item['overtime_detail'];
      final eTime = detail['end_time'] ?? '...';
      timeInfo = '${detail['start_time']} - $eTime';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmissionDetailScreen(submission: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.colorCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: AppTheme.colorCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.overtime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (timeInfo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeInfo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          item['reason'] ?? '-',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
