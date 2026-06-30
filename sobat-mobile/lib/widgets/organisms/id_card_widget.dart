import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/api_config.dart';

class IDCardWidget extends StatefulWidget {
  final dynamic user;

  const IDCardWidget({super.key, required this.user});

  @override
  State<IDCardWidget> createState() => _IDCardWidgetState();
}

class _IDCardWidgetState extends State<IDCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      // Switch the side of the card exactly at 90 degrees (pi / 2)
      if (_controller.value >= 0.5 && _isFront) {
        setState(() {
          _isFront = false;
        });
      } else if (_controller.value < 0.5 && !_isFront) {
        setState(() {
          _isFront = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isAnimating) return;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LANYARD & CLIP LAYER (STATIC)
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Lanyard Strap (Mentok ke atas)
            Positioned(
              bottom: 15,
              child: Container(
                height: 300, // Sangat tinggi agar terlihat tembus ke atas layar
                width: 35,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5CA3), Color(0xFF2372C7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 0),
                    )
                  ],
                ),
              ),
            ),
            // Metal Clip
            Container(
              height: 24,
              width: 45,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                    Colors.grey.shade400
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Center(
                child: Container(
                  width: 25,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            // Clip loop connecting to plastic
            Container(
              height: 15,
              width: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              ),
            )
          ],
        ),

        // PLASTIC HOLDER & ID CARD (ROTATING)
        GestureDetector(
          onTap: _toggleCard,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Add perspective
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(_animation.value);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: _isFront ? _buildFrontCard() : _buildBackCard(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFrontCard() {
    final user = widget.user;
    return Container(
      transform: Matrix4.translationValues(0, -5, 0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10), // The plastic rim
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 200,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // Map Background on Right Side
              Positioned(
                right: -20,
                top: 20,
                bottom: 0,
                width: 200,
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/map.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Row(
                children: [
                  // LEFT SIDE (BLUE)
                  Container(
                    width: 110,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3886B8), Color(0xFF286498)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                backgroundImage: (user?.avatar != null)
                                    ? CachedNetworkImageProvider(
                                        ApiConfig.getStorageUrl(user!.avatar) ??
                                            '',
                                      )
                                    : null,
                                child: (user?.avatar == null)
                                    ? Text(
                                        (user?.name?.isNotEmpty == true)
                                            ? user!.name
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed('/profile/edit');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit,
                                      size: 12, color: Color(0xFF286498)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Icon(Icons.business_center_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(height: 4),
                        const Text(
                          'SRT CORP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        )
                      ],
                    ),
                  ),

                  // RIGHT SIDE (WHITE)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMPLOYEE NAME',
                            style: TextStyle(
                              color: Color(0xFF286498),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'Unknown Name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2C2C2A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            width: double.infinity,
                            color: const Color(0xFF286498),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (user?.position != null &&
                                    user!.position!.isNotEmpty)
                                ? user!.position!
                                : (user?.role ?? 'Staff').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2C2C2A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF286498),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (user?.jobLevel ?? 'STAFF').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.organization ?? 'Unknown Department',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),

                          const Spacer(),

                          // Dummy Barcode
                          _buildStaticBarcode(),
                        ],
                      ),
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

  Widget _buildBackCard() {
    final user = widget.user;
    return Transform(
      // The back side needs to be flipped so the content isn't mirrored!
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Container(
        transform: Matrix4.translationValues(0, -5, 0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10), // The plastic rim
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3886B8), Color(0xFF286498)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: 20,
                  bottom: 0,
                  width: 200,
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/map.png',
                      fit: BoxFit.cover,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      const SizedBox(height: 8),
                      const Text(
                        'This card is the property of SRT CORP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'If found, please return to the nearest SRT CORP office or contact HR Department.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.employeeId ?? 'EMP-000',
                          style: const TextStyle(
                            color: Color(0xFF286498),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(4),
                        child: _buildStaticBarcode(color: Colors.black, height: 24),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to build a static dummy barcode
  Widget _buildStaticBarcode({Color color = const Color(0xFF2C2C2A), double height = 24}) {
    final List<double> widths = [
      2, 1, 3, 1, 1, 2, 4, 1, 2, 2, 1, 3, 1, 1, 2, 1, 3, 2, 1, 1, 4, 1, 2, 1, 3, 2, 1, 1, 2
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: widths.map((w) {
        return Container(
          width: w,
          height: height,
          color: color,
        );
      }).toList(),
    );
  }
}
