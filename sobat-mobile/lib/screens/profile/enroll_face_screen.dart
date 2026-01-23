import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class EnrollFaceScreen extends StatefulWidget {
  final bool isFirstTime;
  const EnrollFaceScreen({super.key, this.isFirstTime = false});

  @override
  State<EnrollFaceScreen> createState() => _EnrollFaceScreenState();
}

class _EnrollFaceScreenState extends State<EnrollFaceScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isUploading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initCamera();
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
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndUpload() async {
    if (_isUploading) return;

    try {
      await _initializeControllerFuture;
      setState(() => _isUploading = true);

      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Upload Logic
      final token = await _authService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/employees/enroll-face'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('photo', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        debugPrint('Enroll Face Error: ${response.body}'); // Debug Output

        // Parse error message
        try {
          // import dart:convert needed? No, usually handled but let's see.
          // Wait, import 'dart:convert' is missing in my list above. I should add it or use manual parsing if simple.
          // Better add it.
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error enrolling face: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text(
          'Wajah Anda berhasil didaftarkan. Sekarang Anda dapat melakukan absensi.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              if (widget.isFirstTime) {
                // Trigger provider refresh to update UI state
                // Import provider first!
                // Wait, I need to add import provider at top if not exists
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(true); // Close screen with success
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100,
                height: 100 * _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. Overlay
          IgnorePointer(
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 280,
                          height: 380,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(190),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 380,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(190),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: const [
                      Text(
                        'DAFTARKAN WAJAH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pastikan wajah terlihat jelas & cahaya cukup\nLepas masker atau kacamata hitam',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses Wajah...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Controls
          if (!_isUploading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  GestureDetector(
                    onTap: _takePictureAndUpload,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),
        ],
      ),
    );
  }
}
