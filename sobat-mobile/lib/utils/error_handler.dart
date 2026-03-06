import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ErrorHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Shows a user-friendly error dialog using AwesomeDialog.
  static void showInternalError(dynamic error, StackTrace? stackTrace) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: 'Oops!',
      desc:
          'Terjadi kesalahan sistem. Tim kami sedang menanganinya.\n\nDetail: ${error.toString()}',
      btnOkOnPress: () {},
      btnOkColor: const Color(0xFFEF4444),
      btnOkText: 'Tutup',
    ).show();
  }

  /// A clean widget to show when a build-time error occurs.
  static Widget get errorWidget {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan Tampilan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maaf, halaman ini tidak dapat dimuat dengan benar sementara waktu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (navigatorKey.currentState?.canPop() ?? false) {
                    navigatorKey.currentState?.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C3ECA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
