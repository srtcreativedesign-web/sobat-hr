import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../services/storage_service.dart';
import 'package:intl/intl.dart';

class SobatOutletDisplayScreen extends StatefulWidget {
  const SobatOutletDisplayScreen({super.key});

  @override
  State<SobatOutletDisplayScreen> createState() => _SobatOutletDisplayScreenState();
}

class _SobatOutletDisplayScreenState extends State<SobatOutletDisplayScreen> {
  String? _deviceUid;
  String? _secretKey;
  String _qrPayload = '';
  Timer? _timer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    _initSobatOutlet();
    try {
      WakelockPlus.enable(); // Keep screen awake
    } catch (e) {
      debugPrint('Wakelock error: $e');
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); // Fullscreen
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock error: $e');
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initSobatOutlet() async {
    final data = await StorageService.getSobatOutletData();
    if (data != null) {
      setState(() {
        _deviceUid = data['device_uid'];
        _secretKey = data['secret_key'];
      });
      _generatePayload();
      _startTimer();
    } else {
      // Data missing, exit sobat outlet
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _generatePayload();
        setState(() {
          _secondsRemaining = 10;
        });
      }
    });
  }

  void _generatePayload() {
    if (_deviceUid == null || _secretKey == null) return;
    
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final message = '$_deviceUid|$timestamp';
    
    // Generate HMAC SHA256
    final key = utf8.encode(_secretKey!);
    final bytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key); 
    final digest = hmacSha256.convert(bytes);
    
    setState(() {
      _qrPayload = '$message|$digest';
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Slate 800
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF419CC3).withValues(alpha: 0.1),
                ),
              ),
            ),
            
            Center(
              child: _qrPayload.isEmpty
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Scan untuk Absensi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'QR Code ini akan diperbarui dalam $_secondsRemaining detik',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF419CC3).withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _qrPayload,
                            version: QrVersions.auto,
                            size: 300.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1E293B),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy HH:mm').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),

            // Back button top left
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
