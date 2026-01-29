import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../config/theme.dart';

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

  // Face Detection
  late FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isFaceGood = false;
  Timer? _captureDebounce;
  bool _isAutoCapturing = false;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // Status Text
  String _statusText = 'INITIALIZING...'; // Start with init
  Color _statusColor = AppTheme.colorEggplant;
  Color _scannerColor = AppTheme.colorCyan;

  // Time
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startClock();

    // Config: Performance = Fast, Contours = None (faster), Landmark = None
    // We only need bounds and classification (eyes/smiling) + tracking
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false, // Turn off heavy features
        enableClassification: true,
        enableLandmarks: false,
      ),
    );

    // Pulse Animation (Rings)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scan Animation (Line/Beam)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: -1.2, end: 1.2).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
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
        ResolutionPreset
            .medium, // Lower res for faster processing? High is ok too.
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
          InputImageRotation.rotation0deg; // Fixed enum

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      // Metadata construction
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
        // Just take the largest face/first face
        final face = faces.first;
        _checkFaceValidation(face);
      } else {
        _resetValidation('NO FACE DETECTED');
      }
    } catch (e) {
      debugPrint("Error processing face: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _checkFaceValidation(Face face) {
    if (_isAutoCapturing) return;

    double rotY = face.headEulerAngleY ?? 0; // Head turn (Left/Right)
    double rotZ = face.headEulerAngleZ ?? 0; // Head tilt (Shoulder to Shoulder)

    // Relaxed Validation
    bool isFacingForward = rotY.abs() < 20; // Increased to 20 deg
    bool isStraight = rotZ.abs() < 20; // Increased to 20 deg

    // Removed Strict Eyes Check (It fails often in bad light)

    if (isFacingForward && isStraight) {
      if (!_isFaceGood) {
        setState(() {
          _isFaceGood = true;
          _statusText = 'HOLD STILL...';
          _statusColor = Colors.white;
          _scannerColor = AppTheme.success;
        });

        // 1 Second hold trigger
        _captureDebounce ??= Timer(
          const Duration(milliseconds: 1000),
          _triggerAutoCapture,
        );
      }
    } else {
      String reason = 'ADJUST FACE';
      if (!isFacingForward) {
        reason = rotY > 0 ? 'TURN RIGHT' : 'TURN LEFT';
      } else if (!isStraight) {
        reason = 'STRAIGHTEN HEAD';
      }

      _resetValidation(reason);
    }
  }

  void _resetValidation(String message) {
    if (_isFaceGood) {
      _captureDebounce?.cancel();
      _captureDebounce = null;
      setState(() {
        _isFaceGood = false;
        _statusText = message;
        _statusColor = AppTheme.colorEggplant;
        _scannerColor = AppTheme.colorCyan;
      });
    } else if (_statusText != message) {
      setState(() {
        _statusText = message;
      });
    }
  }

  Future<void> _triggerAutoCapture() async {
    if (_isAutoCapturing || !mounted) return;

    _captureDebounce?.cancel();

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'CAPTURING...';
      _scannerColor = AppTheme.success;
    });

    try {
      await _controller?.stopImageStream();
      // await Future.delayed(const Duration(milliseconds: 100));

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        // If takePicture fails (e.g. stream busy), wait and retry once
        debugPrint("Capture failed, retrying: $e");
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
        _initCamera(); // Re-init if stream broke
      });
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    _controller?.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _timer.cancel();
    _captureDebounce?.cancel();
    super.dispose();
  }

  Future<void> _takePicture() async {
    // Manual override
    if (_isAutoCapturing) return;
    _captureDebounce?.cancel(); // Cancel auto timer if manual press
    _triggerAutoCapture();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppTheme.colorCyan;
    const bgColor = Color(0xFF10221c);

    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final mediaSize = MediaQuery.of(context).size;
    final scale = 1 / (_controller!.value.aspectRatio * mediaSize.aspectRatio);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(child: CameraPreview(_controller!)),
          ),

          // Background Overlay
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withValues(alpha: 0.6),
                      Colors.transparent,
                      bgColor.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassIconButton(
                        Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Attendance Check',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      _buildGlassIconButton(Icons.settings, onTap: () {}),
                    ],
                  ),
                ),

                const Spacer(),

                Center(
                  child: SizedBox(
                    width: 300,
                    height: 380,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildTechBrackets(_scannerColor),

                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 190 + (190 * _scanAnimation.value),
                              child: Container(
                                width: 320,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      _scannerColor.withValues(alpha: 0.1),
                                      _scannerColor.withValues(alpha: 0.5),
                                      _scannerColor.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _scannerColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        Positioned(
                          bottom: -20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _scannerColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_isFaceGood)
                                  SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _statusColor,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.face_retouching_natural,
                                    size: 12,
                                    color: _statusColor,
                                  ),

                                const SizedBox(width: 8),
                                Text(
                                  _statusText,
                                  style: TextStyle(
                                    color: _statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  'Fit face within brackets\nfor automatic scanning',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0f172a).withValues(alpha: 0.6),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TIME',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentTime,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'LOCATION',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: primaryColor.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: primaryColor,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                widget.address ??
                                                    'Unknown Location',
                                                style: const TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterButton(
                                Icons.cameraswitch,
                                'Flip',
                                onTap: () {},
                              ),
                              const SizedBox(width: 40),
                              GestureDetector(
                                onTap: _isAutoCapturing ? null : _takePicture,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _scannerColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _scannerColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: _statusColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                              _buildFooterButton(
                                Icons.help_outline,
                                'Help',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildGlassIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildFooterButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTechBrackets(Color color) {
    const double size = 30;
    const double thickness = 3;
    const double radius = 10;

    return SizedBox(
      width: 300,
      height: 380,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(radius),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(radius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
