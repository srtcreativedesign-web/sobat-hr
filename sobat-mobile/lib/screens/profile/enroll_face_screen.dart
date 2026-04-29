import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:awesome_dialog/awesome_dialog.dart';

class EnrollFaceScreen extends StatefulWidget {
  final bool isFirstTime;
  const EnrollFaceScreen({super.key, this.isFirstTime = false});

  @override
  State<EnrollFaceScreen> createState() => _EnrollFaceScreenState();
}

class _EnrollFaceScreenState extends State<EnrollFaceScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isSimulator = false;
  bool _isUploading = false;
  final AuthService _authService = AuthService();

  // Face Detection
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _isFaceGood = false;
  Timer? _captureDebounce;
  bool _isAutoCapturing = false;

  // Progress Logic
  double _progressValue = 0.0;
  Timer? _progressTimer;

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
  static const Color _amber400 = Color(0xFFEF9F27);
  static const Color _darkSurface = Color(0xFF444441);
  static const Color _darkCard = Color(0xFF3C3489);

  // Status Text
  String _statusText = 'MENGINISIALISASI...';
  Color _statusColor = _purple600;

  // Manual Capture Fallback
  bool _showManualCapture = false;
  Timer? _manualCaptureTimer;

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

      // Add a small delay to let hardware settle
      await Future.delayed(const Duration(milliseconds: 300));

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
        // iOS front camera streams images in landscape-right orientation
        // regardless of sensorOrientation value; ML Kit expects rotation270deg
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

      final faces = await _faceDetector!.processImage(inputImage);

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
      double diffX = (box.center.dx - _lastFaceBox!.center.dx).abs() / imageSize.width;
      double diffY = (box.center.dy - _lastFaceBox!.center.dy).abs() / imageSize.height;
      
      if (diffX < 0.02 && diffY < 0.02) {
        _stableFrames++;
      } else {
        _stableFrames = 0;
      }
    }
    _lastFaceBox = box;
    bool isStable = _stableFrames >= minStableFrames;

    // 3. Smart Auto-Capture    // 4. Combined Logic
    if (isFacingForward && isStraight && isCentered && isCloseEnough) {
      if (!isStable) {
        _resetValidation('JANGAN BERGERAK...');
        return;
      }
      
      if (!_isAutoCapturing) {
        _startProgressTimer();
        setState(() {
          _isFaceGood = true;
          _statusText = 'MEMINDAI WAJAH...';
          _statusColor = _purple400;
        });
      }
      
      if (_progressValue >= 1.0) {
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
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressValue = 0.0;
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

  Future<void> _takePictureManual() async {
    if (_isAutoCapturing) return;

    _captureDebounce?.cancel();
    _progressTimer?.cancel();
    _manualCaptureTimer?.cancel();

    // Anti-Blur Protection
    if (_stableFrames < minStableFrames) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.bottomSlide,
        title: 'Tidak Stabil',
        desc: 'Pegang HP dengan stabil (gambar buram)',
        btnOkColor: Colors.orange,
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'CAPTURING...';
      _progressValue = 1.0;
      _statusColor = AppTheme.success;
    });

    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
      }
      // Both iOS AVFoundation and Android Camera2 API need time to reconfigure after stopping image stream
      await Future.delayed(const Duration(milliseconds: 500));

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        // Silent fail - retry after delay
        await Future.delayed(const Duration(milliseconds: 500));
        image = await _controller!.takePicture();
      }

      if (!mounted) return;

      // Upload face
      await _uploadFace(image.path);
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      setState(() {
        _isAutoCapturing = false;
        _statusText = 'RETRYING...';
        _initCamera();
      });
    }
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
        _statusText = message;
        _statusColor = _amber400;
      });
    }
  }

  Future<void> _triggerAutoCapture() async {
    if (_isAutoCapturing || !mounted) return;
    _captureDebounce?.cancel();
    _progressTimer?.cancel();

    setState(() {
      _isAutoCapturing = true;
      _statusText = 'CAPTURING...';
      _progressValue = 1.0;
      _statusColor = AppTheme.success;
    });

    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
      }
      // Both iOS AVFoundation and Android Camera2 API need time to reconfigure after stopping image stream
      await Future.delayed(const Duration(milliseconds: 500));

      XFile image;
      try {
        image = await _controller!.takePicture();
      } catch (e) {
        // Silent fail - retry after delay
        await Future.delayed(const Duration(milliseconds: 500));
        image = await _controller!.takePicture();
      }

      if (!mounted) return;

      // Upload face
      await _uploadFace(image.path);
    } catch (e) {
      // Silent fail - error already handled by AppErrorHandler
      setState(() {
        _isAutoCapturing = false;
        _statusText = 'RETRYING...';
        _initCamera();
      });
    }
  }

  Future<void> _uploadFace(String imagePath) async {
    try {
      setState(() {
        _isUploading = true;
        _statusText = 'COMPRESSING...';
      });

      // === STEP 1: Aggressive compression for iPhone high-MP cameras ===
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'face_enroll_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // iPhone 17 Pro Max has 48MP+ camera — need aggressive compression
      final int maxDim = Platform.isIOS ? 640 : 800;
      final int quality = Platform.isIOS ? 40 : 50;

      String finalPath = imagePath;

      try {
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          imagePath,
          targetPath,
          quality: quality,
          minWidth: maxDim,
          minHeight: maxDim,
        );

        if (compressedFile != null) {
          finalPath = compressedFile.path;
          debugPrint(
            '[EnrollFace] Compressed: ${File(finalPath).lengthSync()} bytes',
          );
        } else {
          debugPrint('[EnrollFace] Compression returned null, using original');
        }
      } catch (compressError) {
        debugPrint('[EnrollFace] Compression failed: $compressError');
        // Continue with original file
      }

      // === STEP 2: Validate file size — re-compress if still too large ===
      final fileSize = File(finalPath).lengthSync();
      debugPrint(
        '[EnrollFace] File size: ${(fileSize / 1024).toStringAsFixed(0)} KB',
      );

      if (fileSize > 2 * 1024 * 1024) {
        // > 2MB
        debugPrint(
          '[EnrollFace] Still too large, re-compressing at quality 20',
        );
        final recompressPath = p.join(
          tempDir.path,
          'face_enroll_small_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        try {
          final recompressed = await FlutterImageCompress.compressAndGetFile(
            finalPath,
            recompressPath,
            quality: 20,
            minWidth: 480,
            minHeight: 480,
          );
          if (recompressed != null) {
            finalPath = recompressed.path;
            debugPrint(
              '[EnrollFace] Re-compressed: ${File(finalPath).lengthSync()} bytes',
            );
          }
        } catch (_) {}
      }

      setState(() => _statusText = 'UPLOADING...');

      // === STEP 3: Build URL — ensure no trailing slash (prevents Nginx 308 redirect) ===
      final token = await _authService.getToken();
      final baseUrl = ApiConfig.baseUrl.endsWith('/')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
          : ApiConfig.baseUrl;
      final uploadUrl = '$baseUrl/employees/enroll-face';
      debugPrint('[EnrollFace] URL: $uploadUrl');

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('photo', finalPath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout — koneksi terlalu lambat');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[EnrollFace] Response: ${response.statusCode} ${response.body.substring(0, math.min(200, response.body.length))}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _statusText = 'SUCCESS!');
        await Future.delayed(const Duration(milliseconds: 500));
        _showSuccessDialog();
      } else if (response.statusCode == 308 || response.statusCode == 307) {
        // Nginx redirect — follow manually
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('[EnrollFace] Following redirect to: $redirectUrl');
          // Retry with redirect URL
          var retryRequest = http.MultipartRequest(
            'POST',
            Uri.parse(redirectUrl),
          );
          retryRequest.headers.addAll({
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          });
          retryRequest.files.add(
            await http.MultipartFile.fromPath('photo', finalPath),
          );
          final retryStream = await retryRequest.send().timeout(
            const Duration(seconds: 30),
          );
          final retryResponse = await http.Response.fromStream(retryStream);

          if (!mounted) return;
          if (retryResponse.statusCode == 200) {
            setState(() => _statusText = 'SUCCESS!');
            await Future.delayed(const Duration(milliseconds: 500));
            _showSuccessDialog();
            return;
          } else {
            if (!mounted) return;
            _showErrorDialog('Gagal upload setelah redirect (Error: ${retryResponse.statusCode})');
          }
        } else {
          if (!mounted) return;
          _showErrorDialog('Server redirect error. Coba lagi.');
        }
        setState(() {
          _isUploading = false;
          _isAutoCapturing = false;
          _statusText = 'RETRYING...';
          _initCamera();
        });
      } else {
        String errorMsg = 'Gagal mendaftarkan wajah. Silakan coba lagi.';
        try {
          final decoded = json.decode(response.body);
          if (decoded['message'] != null) errorMsg = decoded['message'];
        } catch (_) {}
        
        if (!mounted) return;
        _showErrorDialog(errorMsg);
      
        setState(() {
          _isUploading = false;
          _isAutoCapturing = false;
          _statusText = 'RETRYING...';
          _initCamera();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Terjadi kesalahan: $e');
        setState(() {
          _isUploading = false;
          _isAutoCapturing = false;
          _statusText = 'RETRYING...';
          _initCamera();
        });
      }
    }
  }

  void _mockSimulatorSequence() {
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
          if (mounted) {
            setState(() => _statusText = 'SUCCESS!');
            _showSuccessDialog();
          }
        });
      });
    });
  }

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Berhasil',
      desc: 'Wajah Anda berhasil didaftarkan!',
      btnOkColor: Colors.green,
      btnOkOnPress: () {
        Navigator.pop(context, true);
      },
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Gagal',
      desc: message,
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();
  }

  void _showInstructionDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      title: 'Pendaftaran Wajah',
      desc: 'Posisikan wajah di tengah lingkaran dan tunggu hingga proses pemindaian selesai.',
      btnOkText: 'SAYA MENGERTI',
      btnOkColor: _purple600,
      btnOkOnPress: () {},
    ).show();
  }

  void _showHelpDialog() {
    _showInstructionDialog();
  }

  @override
  void dispose() {
    _faceDetector?.close();
    _controller?.dispose();
    _captureDebounce?.cancel();
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if ((!_isCameraInitialized || _controller == null) && !_isSimulator) {
      return const Scaffold(
        backgroundColor: _cream,
        body: Center(
          child: CircularProgressIndicator(color: _purple600),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          SafeArea(
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
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _purple600),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          color: _gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
              'REGISTRATION',
              style: TextStyle(
                fontSize: 10,
                color: _gray500,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Enroll Face',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _gray900,
              ),
            ),
          ],
        ),
        _iconButton(
          icon: Icons.help_outline_rounded,
          onTap: _showHelpDialog,
        ),
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
                  'Daftarkan wajah Anda',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _purple600,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Posisikan wajah tepat di tengah',
                  style: TextStyle(
                    fontSize: 11,
                    color: _purple400,
                  ),
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
          _buildInfoBanner(),
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
        child: _bracket(bottomLeft: true, size: size, color: color, width: width),
      ),
      Positioned(
        bottom: offset,
        right: offset,
        child: _bracket(bottomRight: true, size: size, color: color, width: width),
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

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _purple200, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Foto ini akan menjadi referensi utama untuk verifikasi kehadiran Anda.',
              style: TextStyle(fontSize: 11, color: Color(0xFFEEEDFE)),
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
              'Kualitas Biometrik',
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
    return Row(
      children: [
        Expanded(
          child: _infoTile(
            label: 'Keamanan',
            value: 'Liveness Check',
            bgColor: _purple50,
            labelColor: _purple400,
            valueColor: _purple800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoTile(
            label: 'Pencahayaan',
            value: 'Direkomendasikan',
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
          'Gunakan jika auto-capture gagal.',
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


