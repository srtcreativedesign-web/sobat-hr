import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../config/theme.dart';

/// Universal Selfie Camera Screen for Offline Attendance
/// Used by both Operational (after QR scan) and Head Office (after GPS) tracks
class OfflineSelfieScreen extends StatefulWidget {
  final String? address;
  final String trackType; // 'head_office' or 'operational'
  final String? qrCodeData; // For operational track
  final double? gpsLatitude; // For head_office track
  final double? gpsLongitude; // For head_office track

  const OfflineSelfieScreen({
    super.key,
    this.address,
    required this.trackType,
    this.qrCodeData,
    this.gpsLatitude,
    this.gpsLongitude,
  });

  @override
  State<OfflineSelfieScreen> createState() => _OfflineSelfieScreenState();
}

class _OfflineSelfieScreenState extends State<OfflineSelfieScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  bool _cameraInitialized = false;
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Kamera tidak ditemukan');
      }

      // Always default to front camera for selfie/verification
      // even for operational track (after QR scan)
      _currentCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      // If no front camera found, use the first available
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _setupCameraController(_cameras![_currentCameraIndex]);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        _showError('Gagal menginisialisasi kamera: $e');
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error setting up camera controller: $e');
      _showError('Gagal mengatur kamera: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _cameraInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _setupCameraController(_cameras![_currentCameraIndex]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraInitialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Selfie'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Instructions overlay
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.trackType == 'operational'
                            ? 'Ambil foto wide (terlihat orang dan area outlet)'
                            : 'Ambil foto selfie dengan latar belakang terlihat jelas',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.trackType == 'operational'
                            ? 'Gunakan kamera depan (wide angle)'
                            : 'Lokasi: ${widget.address ?? "GPS"}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Camera Switch button
          if (_cameras != null && _cameras!.length > 1)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton.small(
                onPressed: _isProcessing ? null : _toggleCamera,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Capture button
                GestureDetector(
                  onTap: _isProcessing ? null : _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: AppTheme.colorCyan.withValues(alpha: 0.8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                          'Menyimpan...',
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
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take picture
      final XFile photo = await _controller!.takePicture();

      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'offline_selfie_$timestamp.jpg';
      final savedPath = path.join(directory.path, filename);

      // Save photo
      final savedFile = await File(photo.path).copy(savedPath);

      // Read as base64
      final bytes = await savedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (mounted) {
        // Return photo path and base64
        Navigator.pop(context, {
          'photoPath': savedPath,
          'photoBase64': base64String,
          'address': widget.address,
          'trackType': widget.trackType,
          'qrCodeData': widget.qrCodeData,
          'gpsLatitude': widget.gpsLatitude,
          'gpsLongitude': widget.gpsLongitude,
        });
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        _showError('Gagal mengambil foto: $e');
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
