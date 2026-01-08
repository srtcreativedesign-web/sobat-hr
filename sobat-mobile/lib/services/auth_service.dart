import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor untuk attach token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Auto logout jika 401
        if (error.response?.statusCode == 401) {
          await StorageService.clearAll();
        }
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Save token dan user data
        await StorageService.saveToken(token);
        await StorageService.saveUser(userData);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      } else {
        throw Exception(response.data['message'] ?? 'Login gagal');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Login gagal: ${e.message}');
      } else {
        throw Exception('Koneksi gagal. Periksa internet Anda.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<User?> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.profile);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        await StorageService.saveUser(userData);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConfig.logout);
    } catch (e) {
      // Ignore error, tetap clear local storage
    } finally {
      await StorageService.clearAll();
    }
  }

  Future<bool> checkAuth() async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    // Verify token dengan get profile
    final user = await getProfile();
    return user != null;
  }
}
