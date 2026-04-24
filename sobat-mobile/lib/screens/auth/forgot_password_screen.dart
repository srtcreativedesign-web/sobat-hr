import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Request, 1: OTP, 2: Reset
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyPhone = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyReset = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _resetToken = '';
  
  Timer? _countdownTimer;
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = 60;
    _canResend = false;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKeyPhone.currentState!.validate()) return;

    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.requestOtp(phone);
    if (success && mounted) {
      _showSuccess('OTP telah dikirim ke nomor WhatsApp Anda');
      setState(() {
        _currentStep = 1;
      });
      _startCountdown();
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Gagal mengirim OTP');
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKeyOtp.currentState!.validate()) return;

    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final otp = _otpController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final token = await authProvider.verifyOtp(phone, otp);
    if (token != null && mounted) {
      _resetToken = token;
      setState(() {
        _currentStep = 2;
      });
      _countdownTimer?.cancel();
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'OTP tidak valid');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKeyReset.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Konfirmasi password tidak cocok');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _resetToken, 
      _passwordController.text, 
      _confirmPasswordController.text
    );

    if (success && mounted) {
      _showSuccess('Password berhasil diubah. Silakan login kembali.');
      Navigator.pop(context); // Go back to login
    } else if (mounted) {
      _showError(authProvider.errorMessage ?? 'Gagal mereset password');
    }
  }

  Widget _buildStep0() {
    return Form(
      key: _formKeyPhone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lupa Password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.colorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan nomor WhatsApp Anda yang terdaftar pada sistem SOBA HR.',
            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),
          const Text(
            'Nomor WhatsApp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Contoh: 08123456789',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor telepon wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleRequestOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Kirim OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyOtp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verifikasi OTP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.colorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kode OTP 6-digit telah dikirimkan ke WhatsApp Anda (${_phoneController.text}).',
            style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),
          const Text(
            'Kode OTP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '000000',
              filled: true,
              fillColor: Colors.white,
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.length != 6) {
                return 'OTP harus 6 digit';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _canResend
                  ? 'Belum menerima kode?'
                  : 'Kirim ulang dalam 00:${_secondsLeft.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          if (_canResend)
            Center(
              child: TextButton(
                onPressed: _handleRequestOtp,
                child: const Text('Kirim Ulang OTP'),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verifikasi OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buat Password Baru',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.colorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Silakan masukkan password baru Anda.',
            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),
          const Text(
            'Password Baru',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Masukkan password baru',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Konfirmasi Password Baru',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Ketik ulang password baru',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password wajib diisi';
              }
              if (value != _passwordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 0 
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.colorPrimary),
            onPressed: () => Navigator.pop(context),
          )
        : IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.colorPrimary),
            onPressed: () {
              if (_currentStep == 1) {
                setState(() {
                  _currentStep = 0;
                  _countdownTimer?.cancel();
                });
              } else if (_currentStep == 2) {
                // In reset password stage, going back usually means cancelling completely
                // or we can just prohibit returning without resetting
              }
            },
          ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProgressDot(isActive: _currentStep >= 0),
                  _buildProgressLine(isActive: _currentStep >= 1),
                  _buildProgressDot(isActive: _currentStep >= 1),
                  _buildProgressLine(isActive: _currentStep >= 2),
                  _buildProgressDot(isActive: _currentStep >= 2),
                ],
              ),
              const SizedBox(height: 32),
              
              if (_currentStep == 0) _buildStep0(),
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot({required bool isActive}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.colorPrimary : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProgressLine({required bool isActive}) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppTheme.colorPrimary : Colors.grey.shade300,
    );
  }
}
