import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// QR Code Scanner Screen for Operational Track Offline Attendance
class AttendanceQrScannerScreen extends StatefulWidget {
  final Function(String qrCodeData) onScanSuccess;

  const AttendanceQrScannerScreen({super.key, required this.onScanSuccess});

  @override
  State<AttendanceQrScannerScreen> createState() => _AttendanceQrScannerScreenState();
}

class _AttendanceQrScannerScreenState extends State<AttendanceQrScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Pulse animation for scanner frame
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_controller == null || !_controller!.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller?.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller?.stop();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code Absensi'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _getController(),
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.yellow : Colors.white,
                ),
                onPressed: _toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(controller: _getController(), onDetect: _handleScan),

          // Overlay with cutout
          CustomPaint(
            painter: ScannerOverlayPainter(pulseAnimation: _pulseAnimation),
            size: Size.infinite,
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code yang ditempel di dinding outlet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorCyan.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Memproses...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MobileScannerController _getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode],
    );
    return _controller!;
  }

  void _toggleTorch() async {
    final controller = _getController();
    if (!controller.value.isInitialized) {
      debugPrint('Scanner controller not initialized yet');
      return;
    }

    try {
      await controller.toggleTorch();
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;

    // Vibrate on successful scan
    HapticFeedback.vibrate();

    setState(() {
      _isProcessing = true;
    });

    // Return the QR code data
    widget.onScanSuccess(barcode.rawValue!);

    // Navigate back with result
    if (mounted) {
      Navigator.pop(context, barcode.rawValue!);
    }
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> pulseAnimation;

  ScannerOverlayPainter({required this.pulseAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: 250,
      height: 250,
    );

    // Dark overlay
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Create cutout path
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Corner markers with pulse animation
    final cornerPaint = Paint()
      ..color = AppTheme.colorCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;
    final cornerOffset = 8.0 + (pulseAnimation.value * 4);

    // Top-left
    canvas.drawLine(
      Offset(rect.left - cornerOffset, rect.top + cornerLength),
      Offset(rect.left - cornerOffset, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left - cornerOffset, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right + cornerOffset, rect.top + cornerLength),
      Offset(rect.right + cornerOffset, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right + cornerOffset, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left - cornerOffset, rect.bottom - cornerLength),
      Offset(rect.left - cornerOffset, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left - cornerOffset, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right + cornerOffset, rect.bottom - cornerLength),
      Offset(rect.right + cornerOffset, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right + cornerOffset, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      cornerPaint,
    );

    // Scanning line animation
    final scanLinePaint = Paint()
      ..color = AppTheme.colorCyan.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    final scanLineY = rect.top + (rect.height * pulseAnimation.value);
    canvas.drawLine(
      Offset(rect.left, scanLineY),
      Offset(rect.right, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.pulseAnimation.value != pulseAnimation.value;
  }
}
