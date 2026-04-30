import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Color tokens
// ─────────────────────────────────────────────
class _C {
  static const cream = Color(0xFFF7F6F2);
  static const gray100 = Color(0xFFD3D1C7);
  static const gray300 = Color(0xFFB4B2A9);
  static const gray400 = Color(0xFF888780);
  static const gray600 = Color(0xFF5F5E5A);
  static const gray900 = Color(0xFF2C2C2A);
  static const purple50 = Color(0xFFEEEDFE);
  static const purple400 = Color(0xFF7F77DD);
  static const purple600 = Color(0xFF534AB7);
  static const purple800 = Color(0xFF3C3489);
  static const purple900 = Color(0xFF26215C);
  static const green100 = Color(0xFFC0DD97);
  static const green600 = Color(0xFF3B6D11);
  static const amber100 = Color(0xFFFAC775);
  static const amber600 = Color(0xFFBA7517);
  static const blue100 = Color(0xFFBBDEFB);
  static const blue600 = Color(0xFF1565C0);
  static const blue700 = Color(0xFF0E4D92);
  static const white = Colors.white;
}

// ─────────────────────────────────────────────
//  Slip Gaji status enum
// ─────────────────────────────────────────────
enum SlipGajiStatus { proses, selesai, belumAda }

// ─────────────────────────────────────────────
//  Slip Gaji data model
// ─────────────────────────────────────────────
class SlipGajiData {
  final String periode; // e.g. "April 2026"
  final String? gajiPokok;
  final String? tunjangan;
  final String? total;
  final SlipGajiStatus status;
  final String updatedAt; // e.g. "29 Apr 07:58"
  final VoidCallback? onUnduh;
  final VoidCallback? onDetail;

  const SlipGajiData({
    required this.periode,
    this.gajiPokok,
    this.tunjangan,
    this.total,
    this.status = SlipGajiStatus.belumAda,
    this.updatedAt = '',
    this.onUnduh,
    this.onDetail,
  });
}

// ─────────────────────────────────────────────
//  Card 2 — Slip Gaji
// ─────────────────────────────────────────────
class SlipGajiCard extends StatelessWidget {
  final SlipGajiData data;

  const SlipGajiCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.gray100, width: 0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildBreakdown(),
          const SizedBox(height: 14),
          _buildActions(context),
          if (data.status == SlipGajiStatus.proses ||
              data.updatedAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildStatusBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLIP GAJI TERAKHIR',
              style: TextStyle(
                fontSize: 10,
                color: _C.gray400,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.periode,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _C.gray900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.gajiPokok == null ? 'Belum ada data' : 'Data tersedia',
              style: const TextStyle(fontSize: 11, color: _C.gray400),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _C.purple50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: _C.purple600,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdown() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _breakdownRow('Gaji pokok', data.gajiPokok),
          const SizedBox(height: 8),
          _breakdownRow('Tunjangan', data.tunjangan),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: _C.gray100, thickness: 0.5, height: 0),
          ),
          _breakdownRow('Total', data.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String? value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isTotal ? _C.gray900 : _C.gray400,
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        // Skeleton shimmer when null
        value != null
            ? Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isTotal ? _C.purple600 : _C.gray900,
                ),
              )
            : _SkeletonBox(
                width: isTotal
                    ? 72
                    : label == 'Tunjangan'
                    ? 44
                    : 60,
                color: isTotal ? _C.purple50 : _C.gray100,
              ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(label: 'Unduh PDF', onTap: data.onUnduh),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilledButton(label: 'Lihat Detail', onTap: data.onDetail),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final (dot, text, label) = switch (data.status) {
      SlipGajiStatus.proses => (_C.amber100, _C.amber600, 'Proses'),
      SlipGajiStatus.selesai => (_C.green100, _C.green600, 'Selesai'),
      SlipGajiStatus.belumAda => (_C.gray100, _C.gray600, 'Belum ada'),
    };

    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
        ),
        const SizedBox(width: 5),
        Text(
          '$label${data.updatedAt.isNotEmpty ? ' • Diperbarui ${data.updatedAt}' : ''}',
          style: TextStyle(fontSize: 10, color: text),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Slip THR data model
// ─────────────────────────────────────────────
class SlipThrData {
  final String tahun; // e.g. "2026"
  final bool isAvailable;
  final List<String> tags; // e.g. ["Bonus Tahunan"]
  final String updatedAt;
  final VoidCallback? onDetail;

  const SlipThrData({
    required this.tahun,
    this.isAvailable = false,
    this.tags = const ['Bonus Tahunan'],
    this.updatedAt = '',
    this.onDetail,
  });
}

// ─────────────────────────────────────────────
//  Card 3 — Slip THR
// ─────────────────────────────────────────────
class SlipThrCard extends StatelessWidget {
  final SlipThrData data;

  const SlipThrCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.gray100, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [_buildGradientTop(), _buildFooter()]),
    );
  }

  Widget _buildGradientTop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0E4D92),
            Color(0xFF1565C0),
            Color(0xFF2979D6),
            Color(0xFF42A5F5),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUNJANGAN HARI RAYA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tahun ${data.tahun}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Cek Slip THR ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: '✦',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '*Ketuk untuk melihat riwayat',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ...data.tags.map((tag) => _GlassBadge(label: tag)),
                  if (data.isAvailable)
                    _GlassBadge(
                      label: 'Tersedia',
                      dotColor: const Color(0xFF97C459),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: data.onDetail,
      child: Container(
        color: _C.cream,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (data.updatedAt.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: _C.gray400,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Diperbarui ${data.updatedAt}',
                    style: const TextStyle(fontSize: 11, color: _C.gray400),
                  ),
                ],
              )
            else
              const SizedBox(),
            Row(
              children: [
                const Text(
                  'Lihat detail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _C.blue600,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: _C.blue600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared sub-widgets
// ─────────────────────────────────────────────
class _SkeletonBox extends StatelessWidget {
  final double width;
  final Color color;

  const _SkeletonBox({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlineButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled ? _C.gray100.withOpacity(0.3) : _C.cream,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isDisabled ? _C.gray300.withOpacity(0.3) : _C.gray100,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDisabled ? _C.gray400 : _C.gray600,
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FilledButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled ? _C.gray300 : _C.purple600,
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDisabled ? _C.gray600 : const Color(0xFFEEEDFE),
          ),
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;
  final Color? dotColor;

  const _GlassBadge({required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
