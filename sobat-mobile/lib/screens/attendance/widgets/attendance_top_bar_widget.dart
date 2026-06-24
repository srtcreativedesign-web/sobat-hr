import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/offline_attendance_service.dart';

class AttendanceTopBarWidget extends StatelessWidget {
  final bool isOnline;
  final bool isLoadingLocal;
  final bool isWithinRange;
  final String? matchedLocationName;
  final VoidCallback onManualSync;
  final VoidCallback onBackPressed;

  const AttendanceTopBarWidget({
    super.key,
    required this.isOnline,
    required this.isLoadingLocal,
    required this.isWithinRange,
    required this.matchedLocationName,
    required this.onManualSync,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Offline Banner
            if (!isOnline)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colorCyan.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mode Offline Aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Absensi akan disimpan lokal dan terkirim otomatis saat online',
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Manual Sync Button
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.white),
                          onPressed: onManualSync,
                          tooltip: 'Sinkronisasi Sekarang',
                        ),
                        // Show unsynced count
                        FutureBuilder<int>(
                          future: OfflineAttendanceService().getUnsyncedCount(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data! == 0) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${snapshot.data} tertunda',
                                style: const TextStyle(
                                  color: AppTheme.colorCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Original Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppTheme.textDark,
                      onPressed: onBackPressed,
                    ),
                  ),
                  if (!isLoadingLocal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isWithinRange
                            ? Colors.green.withValues(alpha: 0.9)
                            : Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isWithinRange
                                ? Icons.verified
                                : Icons.location_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isWithinRange
                                ? 'Di Area ${matchedLocationName ?? 'Kantor'}'
                                : 'Di Luar Area',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
