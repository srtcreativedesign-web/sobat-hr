import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../config/theme.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SelfieScreen extends StatefulWidget {
  final String? address;
  final String? shiftName;
  final String? status;
  final bool isShifting;

  const SelfieScreen({
    super.key,
    this.address,
    this.shiftName,
    this.status,
    this.isShifting = false,
  });

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

  // Blink Detection Logic
  bool _eyeWasOpen = false;
  bool _blinkDetected = false;

  // Stability Check
  Rect? _lastFaceBox;
  int _stableFrames = 0;
  static const int minStableFrames = 3;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Brand colors (Premium Design)
  static const Color _cream = Color(0xFFF7F6F2);
  static const Color _purple50 = Color(0xFFEEEDFE);
  static const Color _purple200 = Color(0xFFAFA9EC);
  static const Color _purple400 = Color(0xFF7F77DD);
  static const Color _purple600 = Color(0xFF534AB7);
  static const Color _purple800 = Color(0xFF3C3489);
  static const Color _gray100 = Color(0xFFD3D1C7);
  static const Color _gray300 = Color(0xFFB4B2A9);
  static const Color _gray500 = Color(0xFF888780);
  static const Color _gray700 = Color(0xFF5F5E5A);
  static const Color _gray900 = Color(0xFF2C2C2A);
  static const Color _amber200 = Color(0xFFFAC775);
  static const Color _amber400 = Color(0xFFEF9F27);
  static const Color _darkSurface = Color(0xFF444441);
  static const Color _darkCard = Color(0xFF3C3489);

  // Animations

  // Animations

  // Status Text
  String _statusText = 'INITIALIZING...';
  Color _statusColor = AppTheme.colorCyan;

  // Manual Capture Fallback
  bool _showManualCapture = false;
  Timer? _manualCaptureTimer;

  // Time
  late Timer _timer;
  String _currentTime = '';
  String _amPm = '';

  @override
  void initState() {
    super.initState();
    _checkDeviceAndInit();

    // Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start fallback timer
    _manualCaptureTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showManualCapture = true);
      }
    });

    // Show instruction dialog on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionDialog();
    });
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
        ResolutionPreset.medium,
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
      // Silent fail - error already handled by AppErrorHandler
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
      final InputImageRotation imageRotation;
      if (Platform.isIOS) {
        imageRotation = camera.lensDirection == CameraLensDirection.front
            ? InputImageRotation.rotation270deg
            : InputImageRotation.rotation0deg;
      } else {
        imageRotation =
            InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;
      }

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          (Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21);

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
      // Silent fail - error already handled by AppErrorHandler
    } finally {
      _isProcessing = false;
    }
  }

  void _checkFaceValidation(Face face, Size imageSize) {
    if (_isAutoCapturing) return;

    // 1. Position & Angle Validation
    double rotY = face.headEulerAngleY ?? 0;
    double rotZ = face.headEulerAngleZ ?? 0;

    bool isFacingForward = rotY.abs() < 40;
    bool isStraight = rotZ.abs() < 40;

    final Rect box = face.boundingBox;
    final double centerX = imageSize.width / 2;
    final double centerY = imageSize.height / 2;

    double faceCenterX = box.center.dx;
    double faceCenterY = box.center.dy;

    double offsetX = (faceCenterX - centerX).abs() / imageSize.width;
    double offsetY = (faceCenterY - centerY).abs() / imageSize.height;

    double faceWidthPercent = box.width / imageSize.width;

    bool isCentered = offsetX < 0.45 && offsetY < 0.45;
    bool isCloseEnough = faceWidthPercent > 0.10;

    // 2. Stability Check (Anti-Blur)
    if (_lastFaceBox != null) {
      double diffX =
          (box.center.dx - _lastFaceBox!.center.dx).abs() / imageSize.width;
      double diffY =
          (box.center.dy - _lastFaceBox!.center.dy).abs() / imageSize.height;

      if (diffX < 0.02 && diffY < 0.02) {
        _stableFrames++;
      } else {
        _stableFrames = 0;
      }
    }
    _lastFaceBox = box;
    bool isStable = _stableFrames >= minStableFrames;

    // 3. Blink Detection
    double? leftEye = face.leftEyeOpenProbability;
    double? rightEye = face.rightEyeOpenProbability;

    if (leftEye != null && rightEye != null) {
      if (leftEye > 0.7 && rightEye > 0.7) {
        _eyeWasOpen = true;
      } else if (leftEye < 0.25 && rightEye < 0.25 && _eyeWasOpen) {
        _blinkDetected = true;
        _eyeWasOpen = false;
      }
    }

    // 4. Combined Logic
    if (isFacingForward && isStraight && isCentered && isCloseEnough) {
      if (!isStable) {
        _resetValidation('JANGAN BERGERAK...');
        return;
      }

      if (!_isFaceGood) {
        _startProgressTimer();
        setState(() {
          _isFaceGood = true;
          _statusText = 'KEDIPKAN MATA ANDA';
          _statusColor = _purple400;
        });
      }

      if (_blinkDetected) {
        _triggerAutoCapture();
      }
    } else {
      String reason = 'SESUAIKAN';
      if (!isCloseEnough) {
        reason = 'MAJU SEDIKIT';
      } else if (!isCentered) {
        reason = 'POSISIKAN WAJAH DI TENGAH';
      } else if (!isFacingForward) {
        reason = rotY > 0 ? 'MENOLEH KE KANAN' : 'MENOLEH KE KIRI';
      } else if (!isStraight) {
        reason = 'TEGAKKAN KEPALA';
      }

      _resetValidation(reason);
      // Keep blink state for minor adjustments
      if (!isCentered || !isCloseEnough) {
        _blinkDetected = false;
        _eyeWasOpen = false;
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressValue = 0.0;
    // Animate progress to 100% over 4 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
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
        _statusColor = _amber400;
      });
    } else if (_statusText != message) {
      setState(() {
        _statusText = 'POSISIKAN WAJAH';
        _statusColor = _purple600;
      });
    }
  }

  Future<void> _triggerAutoCapture() async {
    if (_isAutoCapturing || !mounted) return;
    _captureDebounce?.cancel();
    _progressTimer?.cancel();

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'SELESAI';
      _progressValue = 1.0;
      _statusColor = AppTheme.success;
    });

    try {
      // 1. First set state to prevent further face detection processing
      if (mounted) setState(() => _isProcessing = true);
      
      // 2. Stop the stream
      await _controller?.stopImageStream();
      
      // 3. IMPORTANT: Give it a long 1-second breath for Xiaomi sensors
      await Future.delayed(const Duration(milliseconds: 1000));

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        // Silent fail - retry after delay
        await Future.delayed(const Duration(milliseconds: 500));
        image = await _controller!.takePicture();
      }

      // Compress Image (Reduce >5MB size to <500KB)
      // Use temporary directory for stable file path on iOS
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 35,
      );

      final finalPath = compressedFile?.path ?? image.path;

      if (!mounted) return;
      Navigator.pop(context, finalPath);
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      setState(() {
        _isAutoCapturing = false;
        _statusText = 'MENCOBA LAGI...';
        _initCamera();
      });
    }
  }

  Future<void> _takePictureManual() async {
    if (_isAutoCapturing) return;

    _captureDebounce?.cancel();
    _progressTimer?.cancel();
    _manualCaptureTimer?.cancel();

    // Anti-Blur for manual capture
    if (_stableFrames < minStableFrames) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pegang HP dengan stabil (gambar buram)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'MEMPROSES...';
      _progressValue = 1.0;
      _statusColor = AppTheme.success;
    });

    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
      }
      // Give it a long 1-second breath
      await Future.delayed(const Duration(milliseconds: 1000));

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        // Silent fail - retry after delay
        await Future.delayed(const Duration(milliseconds: 500));
        image = await _controller!.takePicture();
      }

      // Compress Image (Reduce >5MB size to <500KB)
      // Use temporary directory for stable file path on iOS
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'manual_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 35,
      );

      final finalPath = compressedFile?.path ?? image.path;

      if (!mounted) return;
      Navigator.pop(context, finalPath);
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      setState(() {
        _isAutoCapturing = false;
        _statusText = 'MENCOBA LAGI...';
        _initCamera();
      });
    }
  }

  void _mockSimulatorSequence() {
    // Simulates the face detection process flow for testing layout
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusText = 'WAJAH TERDETEKSI');

      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        _startProgressTimer();
        setState(() {
          _isFaceGood = true;
          _statusText = 'VERIFIKASI (SIM)';
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
    _pulseController.dispose();
    super.dispose();
  }

  void _showInstructionDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      title: 'Petunjuk Selfie',
      desc:
          'Posisikan wajah di dalam lingkaran, pastikan cahaya cukup, dan berkedip saat diminta.',
      btnOkText: 'SAYA MENGERTI',
      btnOkColor: _purple600,
      btnOkOnPress: () {},
    ).show();
  }

  void _showHelpDialog() {
    _showInstructionDialog();
  }

  @override
  Widget build(BuildContext context) {
    if ((!_isCameraInitialized || _controller == null) && !_isSimulator) {
      return const Scaffold(
        backgroundColor: _cream,
        body: Center(child: CircularProgressIndicator(color: _purple600)),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildHintBanner(),
                const SizedBox(height: 20),
                _buildCameraCard(),
                const SizedBox(height: 20),
                _buildProgressSection(),
                const SizedBox(height: 12),
                _buildInfoTiles(),
                const SizedBox(height: 16),
                if (_showManualCapture) _buildManualCaptureButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _iconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        Column(
          children: [
            Text(
              'ABSENSI',
              style: TextStyle(
                fontSize: 10,
                color: _gray500,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Verifikasi Wajah',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _gray900,
              ),
            ),
          ],
        ),
        _iconButton(icon: Icons.help_outline_rounded, onTap: _showHelpDialog),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gray300, width: 0.5),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 16, color: _gray700),
      ),
    );
  }

  Widget _buildHintBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _purple50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _purple400,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siap untuk melakukan absensi?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _purple600,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Pastikan pencahayaan Anda cukup baik',
                  style: TextStyle(fontSize: 11, color: _purple400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard() {
    return Container(
      decoration: BoxDecoration(
        color: _gray900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildScannerFrame(),
                const SizedBox(height: 16),
                _buildStatusChip(),
              ],
            ),
          ),
          _buildTimeLocationCard(),
        ],
      ),
    );
  }

  Widget _buildScannerFrame() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer scanning ring
              Transform.scale(
                scale: _isFaceGood ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isFaceGood ? _purple400 : _gray700,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Camera viewport
              ClipOval(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _darkSurface,
                  ),
                  child: _isSimulator
                      ? const Icon(Icons.face, size: 80, color: Colors.white24)
                      : FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.previewSize!.height,
                            height: _controller!.value.previewSize!.width,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                ),
              ),
              // Corner brackets
              ..._buildCornerBrackets(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerBrackets() {
    const double size = 20;
    const double offset = 10;
    final color = _isFaceGood ? _purple200 : _gray500;
    const width = 2.0;

    return [
      Positioned(
        top: offset,
        left: offset,
        child: _bracket(topLeft: true, size: size, color: color, width: width),
      ),
      Positioned(
        top: offset,
        right: offset,
        child: _bracket(topRight: true, size: size, color: color, width: width),
      ),
      Positioned(
        bottom: offset,
        left: offset,
        child: _bracket(
          bottomLeft: true,
          size: size,
          color: color,
          width: width,
        ),
      ),
      Positioned(
        bottom: offset,
        right: offset,
        child: _bracket(
          bottomRight: true,
          size: size,
          color: color,
          width: width,
        ),
      ),
    ];
  }

  Widget _bracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    required double size,
    required Color color,
    required double width,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BracketPainter(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
        color: color,
        strokeWidth: width,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _statusText,
          style: TextStyle(
            fontSize: 12,
            color: _statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLocationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _amPm,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _purple200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 10, color: _purple200),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _amber200,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.address ?? 'Locating...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Biometric Verification',
              style: TextStyle(fontSize: 11, color: _gray500),
            ),
            Text(
              '${(_progressValue * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _gray700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 4,
            backgroundColor: _gray100,
            valueColor: const AlwaysStoppedAnimation<Color>(_purple600),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTiles() {
    String displayShift = widget.shiftName ?? 'Regular Morning';
    if (widget.isShifting) {
      displayShift = 'Shifting Mode';
    }

    return Row(
      children: [
        Expanded(
          child: _infoTile(
            label: 'Shift',
            value: displayShift,
            bgColor: _purple50,
            labelColor: _purple400,
            valueColor: _purple800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoTile(
            label: 'Status',
            value: widget.status ?? 'Work from Office',
            bgColor: const Color(0xFFF1EFE8),
            labelColor: _gray500,
            valueColor: _gray900,
          ),
        ),
      ],
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required Color bgColor,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: labelColor,
              letterSpacing: 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCaptureButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _takePictureManual,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _purple400,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'MANUAL CAPTURE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AUDIT: Manual capture will be flagged for HRD review.',
          style: TextStyle(color: _gray500, fontSize: 11),
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final Color color;
  final double strokeWidth;

  _BracketPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const r = 8.0;
    final w = size.width;
    final h = size.height;

    if (topLeft) {
      final path = Path();
      path.moveTo(0, 20);
      path.lineTo(0, r);
      path.arcToPoint(const Offset(r, 0), radius: const Radius.circular(r));
      path.lineTo(20, 0);
      canvas.drawPath(path, paint);
    }
    if (topRight) {
      final path = Path();
      path.moveTo(w - 20, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: const Radius.circular(r));
      path.lineTo(w, 20);
      canvas.drawPath(path, paint);
    }
    if (bottomLeft) {
      final path = Path();
      path.moveTo(0, h - 20);
      path.lineTo(0, h - r);
      path.arcToPoint(Offset(r, h), radius: const Radius.circular(r));
      path.lineTo(20, h);
      canvas.drawPath(path, paint);
    }
    if (bottomRight) {
      final path = Path();
      path.moveTo(w - 20, h);
      path.lineTo(w - r, h);
      path.arcToPoint(Offset(w, h - r), radius: const Radius.circular(r));
      path.lineTo(w, h - 20);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
