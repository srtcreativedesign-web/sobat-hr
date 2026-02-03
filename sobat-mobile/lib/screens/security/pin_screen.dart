import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/security_service.dart';
// import '../../services/auth_service.dart'; // Removed unused
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

enum PinMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback onSuccess;

  const PinScreen({super.key, required this.mode, required this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _securityService = SecurityService();
  String _pin = '';
  String _firstPin = ''; // For setup confirmation
  bool _isConfirming = false;
  String _message = '';
  bool _isLoading = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _message = widget.mode == PinMode.setup
        ? 'Buat PIN Keamanan Baru'
        : 'Masukkan PIN Keamanan';

    if (widget.mode == PinMode.verify) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    // Check user preference first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.biometricEnabled) return;

    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheckBiometrics && isDeviceSupported;
      });

      if (_canCheckBiometrics) {
        _authenticate();
      }
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Silakan verifikasi identitas Anda untuk mengakses Payslip',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
        sensitiveTransaction: false,
      );

      if (didAuthenticate && mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('Authentication failed: $e');
      // Do nothing, let user input PIN
    }
  }

  void _onKeyPress(String key) {
    if (_isLoading) return;

    if (key == 'BACK') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length < 6) {
      setState(() => _pin += key);
    }

    if (_pin.length == 6) {
      _onSubmit();
    }
  }

  Future<void> _onSubmit() async {
    if (widget.mode == PinMode.setup) {
      if (!_isConfirming) {
        // Switch to confirmation
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
          _message = 'Konfirmasi PIN Anda';
        });
      } else {
        // Check match
        if (_pin == _firstPin) {
          _callSetupApi();
        } else {
          _showError('PIN tidak cocok. Ulangi.');
          setState(() {
            _pin = '';
            _firstPin = '';
            _isConfirming = false;
            _message = 'Buat PIN Keamanan Baru';
          });
        }
      }
    } else {
      // Verify mode
      _callVerifyApi();
    }
  }

  Future<void> _callSetupApi() async {
    setState(() => _isLoading = true);
    try {
      await _securityService.setupPin(_firstPin, _pin);
      // Refresh user profile to update hasPin status
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).loadUser();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN berhasil dibuat!')));
        widget.onSuccess();
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() {
        _pin = '';
        _firstPin = '';
        _isConfirming = false;
        _message = 'Buat PIN Keamanan Baru';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callVerifyApi() async {
    setState(() => _isLoading = true);
    try {
      final isValid = await _securityService.verifyPin(_pin);
      if (isValid) {
        widget.onSuccess();
      } else {
        _showError('PIN Salah');
        setState(() => _pin = '');
      }
    } catch (e) {
      _showError(e.toString());
      setState(() => _pin = '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 48, color: AppTheme.colorEggplant),
          const SizedBox(height: 24),
          Text(
            _message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 32),

          // DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length
                      ? AppTheme.colorEggplant
                      : Colors.grey.shade200,
                ),
              );
            }),
          ),

          const SizedBox(height: 64),

          if (_isLoading) const CircularProgressIndicator() else _buildNumpad(),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumBtn('1'),
            const SizedBox(width: 24),
            _buildNumBtn('2'),
            const SizedBox(width: 24),
            _buildNumBtn('3'),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumBtn('4'),
            const SizedBox(width: 24),
            _buildNumBtn('5'),
            const SizedBox(width: 24),
            _buildNumBtn('6'),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumBtn('7'),
            const SizedBox(width: 24),
            _buildNumBtn('8'),
            const SizedBox(width: 24),
            _buildNumBtn('9'),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Biometric button (only if available and in verify mode)
            if (_canCheckBiometrics &&
                widget.mode == PinMode.verify &&
                context.watch<AuthProvider>().biometricEnabled) ...[
              _buildBiometricBtn(),
              const SizedBox(width: 24),
            ] else ...[
              const SizedBox(width: 72), // Empty space placeholder
              const SizedBox(width: 24),
            ],
            _buildNumBtn('0'),
            const SizedBox(width: 24),
            _buildBackspaceBtn(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumBtn(String num) {
    return InkWell(
      onTap: () => _onKeyPress(num),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            num,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceBtn() {
    return InkWell(
      onTap: () => _onKeyPress('BACK'),
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(Icons.backspace_outlined, color: AppTheme.textDark),
        ),
      ),
    );
  }

  Widget _buildBiometricBtn() {
    return InkWell(
      onTap: _authenticate,
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: Icon(
            Icons.fingerprint,
            size: 32,
            color: AppTheme.colorEggplant,
          ),
        ),
      ),
    );
  }
}
