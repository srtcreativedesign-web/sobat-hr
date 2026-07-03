import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/sobat_outlet_service.dart';
import '../../services/storage_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class SobatOutletLoginScreen extends StatefulWidget {
  const SobatOutletLoginScreen({super.key});

  @override
  State<SobatOutletLoginScreen> createState() => _SobatOutletLoginScreenState();
}

class _SobatOutletLoginScreenState extends State<SobatOutletLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceCodeController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  final _outletService = SobatOutletService();

  Future<String> _getDeviceUid() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique ID on Android
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      debugPrint('Failed to get device name: $e');
    }
    return 'Unknown Device';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final deviceUid = await _getDeviceUid();
      final deviceName = await _getDeviceName();
      final result = await _outletService.login(
        deviceCode: _deviceCodeController.text.trim(),
        pin: _pinController.text.trim(),
        deviceUid: deviceUid,
        deviceName: deviceName,
      );

      // Save to storage
      await StorageService.saveSobatOutletData(
        deviceUid,
        result['secret_key'],
      );

      if (mounted) {
        // Navigate to Home
        Navigator.pushReplacementNamed(context, '/outlet-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.store_rounded,
                    size: 80,
                    color: AppTheme.colorCyan,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SOBAT OUTLET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.colorPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mode Mesin Absensi Khusus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _deviceCodeController,
                    decoration: InputDecoration(
                      labelText: 'ID Perangkat (Contoh: DEV-ABCDEF)',
                      prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) =>
                        value!.isEmpty ? 'Masukkan ID Perangkat' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'PIN (6 Digit)',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      counterText: "",
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Masukkan PIN';
                      if (value.length != 6) return 'PIN harus 6 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorCyan,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'AKTIVASI MESIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
