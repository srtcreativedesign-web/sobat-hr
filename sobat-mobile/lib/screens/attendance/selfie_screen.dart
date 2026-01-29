import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../config/theme.dart';

import 'package:device_info_plus/device_info_plus.dart'; // [NEW]

class SelfieScreen extends StatefulWidget {
  final String? address;
  const SelfieScreen({super.key, this.address});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isSimulator = false; // [NEW]

  // Face Detection
  late FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isFaceGood = false;
  Timer? _captureDebounce;
  bool _isAutoCapturing = false;

  // Progress Logic
  double _progressValue = 0.0;
  Timer? _progressTimer;

  // Animations

  // Animations

  // Status Text
  String _statusText = 'INITIALIZING...';
  Color _statusColor = AppTheme.colorCyan;

  // Time
  late Timer _timer;
  String _currentTime = '';
  String _amPm = '';

  @override
  void initState() {
    super.initState();
    _checkDeviceAndInit();
  }

  Future<void> _checkDeviceAndInit() async {
    bool isSimulator = false;
    if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      isSimulator = !iosInfo.isPhysicalDevice;
    }

    if (mounted) {
      setState(() {
        _isSimulator = isSimulator;
      });
    }

    if (isSimulator) {
      setState(() => _statusText = 'SIMULATOR MODE');
      _mockSimulatorSequence();
    } else {
      _initCamera();
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableContours: false,
          enableClassification: true,
          enableLandmarks: false,
        ),
      );
    }
    _startClock();
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _currentTime = DateFormat('hh:mm').format(now);
        _amPm = DateFormat('a').format(now);
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _statusText = 'FINDING FACE...';
        });
        _startImageStream();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      setState(() => _statusText = 'CAMERA ERROR');
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) {
      if (_isProcessing || _isAutoCapturing) return;
      _isProcessing = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final camera = _controller!.description;
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        _checkFaceValidation(face, imageSize);
      } else {
        _resetValidation('NO FACE DETECTED');
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _checkFaceValidation(Face face, Size imageSize) {
    if (_isAutoCapturing) return;

    double rotY = face.headEulerAngleY ?? 0;
    double rotZ = face.headEulerAngleZ ?? 0;

    bool isFacingForward = rotY.abs() < 15;
    bool isStraight = rotZ.abs() < 15;

    final Rect box = face.boundingBox;
    final double centerX = imageSize.width / 2;
    final double centerY = imageSize.height / 2;
    // NOTE: ML Kit coordinates might be relative to the image sensor buffer.
    // For front camera, X might be mirrored.

    double faceCenterX = box.center.dx;
    double faceCenterY = box.center.dy;

    double offsetX = (faceCenterX - centerX).abs() / imageSize.width;
    double offsetY = (faceCenterY - centerY).abs() / imageSize.height;

    double faceWidthPercent = box.width / imageSize.width;
    // double faceHeightPercent = box.height / imageSize.height;

    // Thresholds
    bool isCentered = offsetX < 0.25 && offsetY < 0.25;
    bool isCloseEnough = faceWidthPercent > 0.15;

    if (isFacingForward && isStraight && isCentered && isCloseEnough) {
      if (!_isFaceGood) {
        _startProgressTimer();
        setState(() {
          _isFaceGood = true;
          _statusText = 'VERIFYING';
          _statusColor = AppTheme.colorCyan; // Cyan for good
        });

        _captureDebounce ??= Timer(
          const Duration(seconds: 2),
          _triggerAutoCapture,
        );
      }
    } else {
      String reason = 'ADJUST';

      if (!isCloseEnough) {
        reason = 'MOVE CLOSER';
      } else if (!isCentered) {
        reason = 'CENTER FACE';
      } else if (!isFacingForward) {
        reason = rotY > 0 ? 'TURN RIGHT' : 'TURN LEFT';
      } else if (!isStraight) {
        reason = 'STRAIGHTEN HEAD';
      }

      _resetValidation(reason);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressValue = 0.0;
    // Animate progress to 100% over 2 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        _progressValue += 0.01;
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          timer.cancel();
        }
      });
    });
  }

  void _resetValidation(String message) {
    if (_isFaceGood) {
      _captureDebounce?.cancel();
      _captureDebounce = null;
      _progressTimer?.cancel();
      setState(() {
        _isFaceGood = false;
        _progressValue = 0.0;
        _statusText = message;
        _statusColor = Colors.orangeAccent;
      });
    } else if (_statusText != message) {
      setState(() {
        _statusText = message;
        _statusColor = Colors.orangeAccent;
      });
    }
  }

  Future<void> _triggerAutoCapture() async {
    if (_isAutoCapturing || !mounted) return;
    _captureDebounce?.cancel();
    _progressTimer?.cancel();

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'COMPLETED';
      _progressValue = 1.0;
      _statusColor = AppTheme.success;
    });

    try {
      await _controller?.stopImageStream();

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 500));
        image = await _controller!.takePicture();
      }

      if (!mounted) return;
      Navigator.pop(context, image.path);
    } catch (e) {
      debugPrint("Error auto-capturing: $e");
      setState(() {
        _isAutoCapturing = false;
        _statusText = 'RETRYING...';
        _initCamera();
      });
    }
  }

  void _mockSimulatorSequence() {
    // Simulates the face detection process flow for testing layout
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusText = 'FACE DETECTED');

      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        _startProgressTimer();
        setState(() {
          _isFaceGood = true;
          _statusText = 'VERIFYING (SIM)';
          _statusColor = AppTheme.colorCyan;
        });

        Timer(const Duration(seconds: 2), () {
          if (mounted) _triggerAutoCapture();
        });
      });
    });
  }

  @override
  void dispose() {
    _faceDetector.close();
    _controller?.dispose();
    _timer.cancel();
    _captureDebounce?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tips Selfie',
          style: TextStyle(
            color: AppTheme.colorCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpItem('1. Posisikan wajah di dalam lingkaran.'),
            SizedBox(height: 8),
            _HelpItem('2. Pastikan cahaya cukup.'),
            SizedBox(height: 8),
            _HelpItem('3. Tunggu hingga progress bar penuh.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if ((!_isCameraInitialized || _controller == null) && !_isSimulator) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.colorCyan),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    // Calculate hole size (Circle)
    final double holeSize = size.width * 0.75;
    final double holeRadius = holeSize / 2;
    // Move up by 15% of the half-height (approx -0.15 alignment)
    // Alignment(0, -0.2) -> pixel offset = -0.2 * (height/2)
    const double alignY = -0.25;
    final double verticalOffset = alignY * (size.height / 2);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview (Full Screen Cover) OR Simulator Placeholder
          SizedBox(
            width: size.width,
            height: size.height,
            child: _isSimulator
                ? Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.face, size: 80, color: Colors.white24),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.previewSize!.height,
                      height: _controller!.value.previewSize!.width,
                      child: CameraPreview(_controller!),
                    ),
                  ),
          ),

          // 2. Dark Overlay with Hole
          CustomPaint(
            size: size,
            painter: HoleOverlayPainter(
              holeRadius: holeRadius,
              overlayColor: Colors.black.withValues(alpha: 0.85),
              verticalOffset: verticalOffset, // Pass offset
            ),
          ),

          // 3. Ring Overlay (Moved OUT of SafeArea)
          // 3. Ring Overlay (Moved OUT of SafeArea)
          Positioned(
            top: (size.height / 2) + verticalOffset - (holeSize / 2),
            left: (size.width - holeSize) / 2,
            child: SizedBox(
              width: holeSize,
              height: holeSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(holeSize, holeSize),
                    painter: ScannerRingPainter(color: _statusColor),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Transform.translate(
                      // Push down to avoid overlap with ring border
                      offset: const Offset(0, 30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. UI Layer
          SafeArea(
            child: Stack(
              children: [
                // Top & Bottom Content
                Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircleBtn(
                            Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Attendance Check',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildCircleBtn(Icons.settings, onTap: () {}),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recognition Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.colorEggplant.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.face,
                              size: 16,
                              color: AppTheme.colorCyan,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Face Recognition',
                              style: TextStyle(
                                color: AppTheme.colorCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Instruction Text
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 40,
                      ), // Increased spacing
                      child: Text(
                        'Align your face within the circle\nfor automatic scanning',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Bottom Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.colorEggplant, // Updated to Brand Color
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time and Location Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT TIME',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _currentTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _amPm,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Location Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.colorCyan.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppTheme.colorCyan,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 100,
                                      ),
                                      child: Text(
                                        widget.address ?? 'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.colorCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Processing Biometrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Processing biometrics...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(_progressValue * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppTheme.colorCyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.colorCyan,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Footer Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Help Button
                              _buildFooterBtn(
                                Icons.help_outline,
                                'HELP',
                                onTap: _showHelpDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFooterBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String text;
  const _HelpItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 13,
      ),
    );
  }
}

class ScannerRingPainter extends CustomPainter {
  final Color color;

  ScannerRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.5),
          color,
          color.withValues(alpha: 0.5),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 2, false, paint);

    // Draw thin solid border inside
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.3);

    canvas.drawCircle(Offset(radius, radius), radius - 4, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ScannerRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class HoleOverlayPainter extends CustomPainter {
  final double holeRadius;
  final Color overlayColor;
  final double verticalOffset; // Added offset

  HoleOverlayPainter({
    required this.holeRadius,
    required this.overlayColor,
    this.verticalOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(
              size.width / 2,
              (size.height / 2) + verticalOffset,
            ), // Apply offset
            radius: holeRadius,
          ),
        )
        ..close(),
    );

    canvas.drawPath(path, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
