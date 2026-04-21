import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';

class FinanceComingSoonScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const FinanceComingSoonScreen({super.key, this.onBack});

  @override
  State<FinanceComingSoonScreen> createState() =>
      _FinanceComingSoonScreenState();
}

class _FinanceComingSoonScreenState extends State<FinanceComingSoonScreen> {
  int _currentImageIndex = 0;
  Timer? _timer;

  final List<String> _images = [
    'assets/images/finance.png',
    'assets/images/finance2.png',
  ];

  @override
  void initState() {
    super.initState();
    _startImageRotation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startImageRotation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      body: Stack(
        children: [
          // --- ABSTRACT BACKGROUND VISUALS ---
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: MediaQuery.of(context).size.width * 0.2,
            child: _buildBlurBlob(
              600,
              600,
              const Color(0xFF5F9EFB).withValues(alpha: 0.15),
              120,
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            right: -100,
            child: _buildBlurBlob(
              400,
              400,
              const Color(0xFFDECCFD).withValues(alpha: 0.15),
              100,
            ),
          ),

          // --- HEADER (mimicking TopAppBar) ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F3FA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Color(0xFF005EB6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Keuangan',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF005EB6),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile').then((_) {
                        if (widget.onBack != null) widget.onBack!();
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE6E8F1),
                      backgroundImage:
                          user?.avatar != null
                              ? NetworkImage(
                                ApiConfig.getStorageUrl(user!.avatar!) ?? '',
                              )
                              : null,
                      child:
                          user?.avatar == null
                              ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, bottom: 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- HERO CENTERPIECE ---
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Glow
                        Transform.rotate(
                          angle: 0.2,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF005EB6).withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        // Glass layer with Image Carousel
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(48),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.4),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 1000),
                                  transitionBuilder: (
                                    Widget child,
                                    Animation<double> animation,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    _images[_currentImageIndex],
                                    key: ValueKey<int>(_currentImageIndex),
                                    width: 140,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Floating Logic Elements
                        Positioned(
                          top: 20,
                          right: 20,
                          child: _buildFloatingIcon(
                            Icons.account_tree_outlined,
                            const Color(0xFF005EB6),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: _buildFloatingIcon(
                            Icons.analytics_outlined,
                            const Color(0xFF665882),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- TEXT MESSAGING ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: const Color(0xFF2F323A),
                            ),
                            children: [
                              const TextSpan(text: 'Fitur Masih Dalam '),
                              TextSpan(
                                text: 'Pengembangan',
                                style: TextStyle(
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [
                                        Color(0xFF005EB6),
                                        Color(0xFF5F9EFB),
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kami sedang merancang fitur masa depan untuk meningkatkan produktivitas Anda. Segera hadir di genggaman Anda.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF5C5F68),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- ACTION CLUSTER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: widget.onBack,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005EB6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 20,
                              shadowColor: const Color(
                                0xFF005EB6,
                              ).withValues(alpha: 0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Kembali',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Beri Tahu Saya',
                            style: TextStyle(
                              color: Color(0xFF005EB6),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- PROGRESS INDICATOR ---
                  Container(
                    width: 280,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'KESIAPAN SISTEM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF777B84),
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '20%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF005EB6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                color: const Color(0xFFECEDF6),
                              ),
                              Container(
                                height: 6,
                                width: 280 * 0.20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005EB6),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF005EB6,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 10,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurBlob(double w, double h, Color color, double blur) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(w / 2),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
