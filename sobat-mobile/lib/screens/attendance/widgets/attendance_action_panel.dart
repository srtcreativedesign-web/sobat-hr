import 'package:flutter/material.dart';
import '../../../widgets/progress_journey_path.dart';
import '../../../widgets/slide_action_button.dart';
import '../../../providers/attendance_provider.dart';

class AttendanceActionPanel extends StatelessWidget {
  final String attendanceType;
  final bool hasCheckedIn;
  final bool canCheckIn;
  final bool canCheckOut;
  final bool hasCheckedOut;
  final bool isLateRestricted;
  final bool isWithinRange;
  final bool isOperational;
  final bool isLoadingLocal;
  final String? currentAddress;
  final Map<String, dynamic>? todayAttendance;
  final TextEditingController fieldNotesController;
  final AttendanceProvider attendanceProvider;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final Function(String) showError;

  const AttendanceActionPanel({
    super.key,
    required this.attendanceType,
    required this.hasCheckedIn,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.hasCheckedOut,
    required this.isLateRestricted,
    required this.isWithinRange,
    required this.isOperational,
    required this.isLoadingLocal,
    required this.currentAddress,
    required this.todayAttendance,
    required this.fieldNotesController,
    required this.attendanceProvider,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper: 1 Absen Kantor -> 2 Selesai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: Color(0xFF419CC3), shape: BoxShape.circle),
                      child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        attendanceType == 'field'
                            ? 'Absen Luar'
                            : 'Absen Kantor',
                        style: const TextStyle(
                            color: Color(0xFF419CC3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    Text('Selesai',
                        style: TextStyle(
                            color: hasCheckedIn
                                ? const Color(0xFF419CC3)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: hasCheckedIn
                              ? const Color(0xFF419CC3)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text('2',
                              style: TextStyle(
                                  color: hasCheckedIn
                                      ? Colors.white
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold))),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Journey Path
            ProgressJourneyPath(isCompleted: hasCheckedIn),

            const SizedBox(height: 16),

            // Toggle Attendance Type (Visible if not finished today)
            if (canCheckIn || canCheckOut) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            attendanceProvider.setAttendanceType('office'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: attendanceType == 'office'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: attendanceType == 'office'
                                ? [
                                    const BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text('Absen Kantor',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: attendanceType == 'office'
                                      ? const Color(0xFF419CC3)
                                      : Colors.grey.shade600)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            attendanceProvider.setAttendanceType('field'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: attendanceType == 'field'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: attendanceType == 'field'
                                ? [
                                    const BoxShadow(
                                        color: Colors.black12, blurRadius: 4)
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text('Absen Luar',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: attendanceType == 'field'
                                      ? const Color(0xFF419CC3)
                                      : Colors.grey.shade600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Field Notes Input
            if (attendanceType == 'field') ...[
              TextField(
                controller: fieldNotesController,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: 'Keterangan (Wajib)',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  hintText: 'Contoh: Meeting dengan Client A',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF419CC3)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],

            // Show Active Check-in Type if already Checked In
            if (hasCheckedIn) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // blue-50
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
                ),
                child: Row(
                  children: [
                    Icon(
                      (todayAttendance?['attendance_type'] == 'field')
                          ? Icons.commute
                          : Icons.store,
                      size: 16,
                      color: const Color(0xFF419CC3),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (todayAttendance?['attendance_type'] == 'field')
                          ? 'Mode: Absen Luar (Dinas)'
                          : 'Mode: Absen Kantor',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF419CC3)),
                    ),
                    if (todayAttendance?['is_offline_local'] == true) ...[
                      const Spacer(),
                      Icon(
                        todayAttendance?['is_synced'] == true
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        size: 14,
                        color: const Color(0xFF419CC3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        todayAttendance?['is_synced'] == true
                            ? 'Ter-sync'
                            : 'Lokal',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF419CC3)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Location Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        color: Color(0xFF419CC3), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Anda',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentAddress ?? 'Mencari lokasi...',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                  // Accuracy badge
                  if (isWithinRange)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Akurat',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Slide Button
            if (canCheckIn)
              SlideActionWidget(
                text: 'Geser untuk Masuk',
                backgroundColor: const Color(0xFF419CC3),
                onSubmit: () {
                  if (attendanceType == 'office' &&
                      !isWithinRange &&
                      !isOperational) {
                    showError(
                        'Jarak terlalu jauh dari lokasi kantor. Silakan pilih mode Absen Luar jika Anda sedang bertugas di luar.');
                    return;
                  }
                  if (!isLoadingLocal &&
                      (attendanceType == 'field' ||
                          isWithinRange ||
                          isOperational)) {
                    onCheckIn();
                  }
                },
              )
            else if (canCheckOut)
              SlideActionWidget(
                text: isLateRestricted
                    ? 'Menunggu Approval'
                    : 'Geser untuk Pulang',
                backgroundColor: const Color(0xFF10B981), // Green for go home
                thumbIcon: Icons.logout_rounded,
                onSubmit: () {
                  if (attendanceType == 'office' &&
                      !isWithinRange &&
                      !isOperational) {
                    showError(
                        'Jarak terlalu jauh dari lokasi kantor. Silakan pilih mode Absen Luar jika Anda sedang bertugas di luar.');
                    return;
                  }
                  if (!isLateRestricted &&
                      !isLoadingLocal &&
                      (attendanceType == 'field' ||
                          isWithinRange ||
                          isOperational)) {
                    onCheckOut();
                  }
                },
              )
            else if (hasCheckedOut)
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Center(
                  child: Text('Absensi Selesai',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              )
          ],
        ),
      ),
    );
  }
}
