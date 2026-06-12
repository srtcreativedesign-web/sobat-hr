import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';

class ProgressJourneyPath extends StatelessWidget {
  final bool isCompleted;

  const ProgressJourneyPath({super.key, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step 1: Office Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // blue-50
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_rounded, color: Color(0xFF1C3ECA), size: 24),
          ),
          
          // Wavy Dotted Line
          Expanded(
            child: CustomPaint(
              painter: WavyDottedLinePainter(
                color: isCompleted ? const Color(0xFF1C3ECA) : const Color(0xFFE2E8F0), // blue vs gray
              ),
              child: const SizedBox(height: 20),
            ),
          ),
          
          // Step 2: Destination Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF1C3ECA) : const Color(0xFFF1F5F9), // blue vs gray-100
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded, 
              color: isCompleted ? Colors.white : const Color(0xFF94A3B8), 
              size: 20
            ),
          ),
        ],
      ),
    );
  }
}

class WavyDottedLinePainter extends CustomPainter {
  final Color color;

  WavyDottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    
    // Create a bezier curve or sine wave
    final width = size.width;
    final height = size.height;
    
    path.cubicTo(
      width * 0.25, height * 0.1, // control point 1
      width * 0.75, height * 0.9, // control point 2
      width, height / 2,         // end point
    );

    // Draw dashed path
    const double dashWidth = 6.0;
    const double dashSpace = 6.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final ext = pathMetric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(ext, paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // Reset for the next metric (if any)
    }
  }

  @override
  bool shouldRepaint(covariant WavyDottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
