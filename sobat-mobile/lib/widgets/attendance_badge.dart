import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Enum status absensi
// ─────────────────────────────────────────────
enum AttendanceStatus {
  onTime,
  earlyLeave,
  late,
  absent,
  inProgress,
}

// ─────────────────────────────────────────────
//  Badge widget
// ─────────────────────────────────────────────
class AttendanceBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool showDot;

  const AttendanceBadge({
    super.key,
    required this.status,
    this.showDot = true,
  });

  _BadgeStyle get _style {
    switch (status) {
      case AttendanceStatus.onTime:
        return _BadgeStyle(
          bg:   const Color(0xFFD6EFBA),
          dot:  const Color(0xFF97C459),
          text: const Color(0xFF27500A),
          label: 'Tepat Waktu',
        );
      case AttendanceStatus.earlyLeave:
        return _BadgeStyle(
          bg:   const Color(0xFFFAEEDA),
          dot:  const Color(0xFFEF9F27),
          text: const Color(0xFF854F0B),
          label: 'Keluar Lebih Awal',
        );
      case AttendanceStatus.late:
        return _BadgeStyle(
          bg:   const Color(0xFFFFE4E4),
          dot:  const Color(0xFFF08080),
          text: const Color(0xFFA32D2D),
          label: 'Terlambat',
        );
      case AttendanceStatus.absent:
        return _BadgeStyle(
          bg:   const Color(0xFFF1EFE8),
          dot:  const Color(0xFFB4B2A9),
          text: const Color(0xFF5F5E5A),
          label: 'Tidak Hadir',
        );
      case AttendanceStatus.inProgress:
        return _BadgeStyle(
          bg:   const Color(0xFFEEEDFE),
          dot:  const Color(0xFF7F77DD),
          text: const Color(0xFF3C3489),
          label: 'Sedang Berlangsung',
          animateDot: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            s.animateDot
                ? _PulsingDot(color: s.dot)
                : _StaticDot(color: s.dot),
            const SizedBox(width: 6),
          ],
          Text(
            s.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: s.text,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Style model
// ─────────────────────────────────────────────
class _BadgeStyle {
  final Color bg;
  final Color dot;
  final Color text;
  final String label;
  final bool animateDot;

  const _BadgeStyle({
    required this.bg,
    required this.dot,
    required this.text,
    required this.label,
    this.animateDot = false,
  });
}

// ─────────────────────────────────────────────
//  Static dot
// ─────────────────────────────────────────────
class _StaticDot extends StatelessWidget {
  final Color color;
  const _StaticDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─────────────────────────────────────────────
//  Pulsing dot (untuk status inProgress)
// ─────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}
