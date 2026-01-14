import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class SecurityService {
  late final Dio _dio;

  SecurityService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> setupPin(String pin, String pinConfirmation) async {
    try {
      final response = await _dio.post(
        '/security/pin/setup',
        data: {'pin': pin, 'pin_confirmation': pinConfirmation},
      );
      // Success
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data['message'] != null) {
          throw Exception(data['message']);
        }
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          throw Exception(errors.values.first.first);
        }
      }
      throw Exception('Gagal membuat PIN: ${e.message}');
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      await _dio.post('/security/pin/verify', data: {'pin': pin});
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false;
      }
      throw Exception('Gagal verifikasi PIN: ${e.message}');
    }
  }
}
