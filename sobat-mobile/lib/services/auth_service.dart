import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
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

    // Add interceptor untuk attach token
    _dio.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // DEBUG: Print full user data
        print('=== LOGIN API RESPONSE ===');
        print('Full userData: $userData');
        if (userData['employee'] != null) {
          print('Employee data: ${userData['employee']}');
          print('Track: ${userData['employee']['track']}');
          print('Position: ${userData['employee']['position']}');
        }
        print('========================');

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
          e.response?.data['message'] ?? 'Login gagal: ${e.message}',
        );
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

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userData = await StorageService.getUser();
      return userData;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateEmployee(int id, Object payload) async {
    try {
      final isFormData = payload is FormData;
      final response = await (isFormData
          ? _dio.post('${ApiConfig.employees}/$id', data: payload)
          : _dio.put('${ApiConfig.employees}/$id', data: payload));
      if (response.statusCode == 200) {
        // Optionally refresh stored user/profile
        await getProfile();
        return;
      }
      throw Exception('Gagal memperbarui data karyawan');
    } on DioException catch (e) {
      // Handle validation errors (422) from Laravel
      final status = e.response?.statusCode;
      if (status == 422) {
        final data = e.response?.data;
        // Debug: print raw response body for easier inspection
        print(
          'AuthService.updateEmployee 422 response raw: ${jsonEncode(data)}',
        );
        final errors = data != null && data['errors'] != null
            ? data['errors'] as Map<String, dynamic>
            : null;
        if (errors != null) {
          final msgs = errors.values
              .expand((v) => (v as List).map((i) => i.toString()))
              .join(' | ');
          // include raw data for debugging
          throw Exception('$msgs | raw:${jsonEncode(data)}');
        }
        final msg = data != null && data['message'] != null
            ? data['message'].toString()
            : 'Validasi gagal';
        throw Exception('$msg | raw:${jsonEncode(data)}');
      }
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<void> createEmployee(Object payload) async {
    try {
      final response = await _dio.post(ApiConfig.employees, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await getProfile();
        return;
      }
      throw Exception('Gagal membuat data karyawan');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 422) {
        final data = e.response?.data;
        // Debug: print raw response body for easier inspection
        print(
          'AuthService.createEmployee 422 response raw: ${jsonEncode(data)}',
        );
        final errors = data != null && data['errors'] != null
            ? data['errors'] as Map<String, dynamic>
            : null;
        if (errors != null) {
          final msgs = errors.values
              .expand((v) => (v as List).map((i) => i.toString()))
              .join(' | ');
          // include raw data for debugging
          throw Exception('$msgs | raw:${jsonEncode(data)}');
        }
        final msg = data != null && data['message'] != null
            ? data['message'].toString()
            : 'Validasi gagal';
        throw Exception('$msg | raw:${jsonEncode(data)}');
      }
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<Map<String, dynamic>?> getSupervisorCandidate({
    required int organizationId,
    required String jobLevel,
    required String track,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.employees}/supervisor-candidate',
        queryParameters: {
          'organization_id': organizationId,
          'job_level': jobLevel,
          'track': track,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/auth/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Gagal mengubah password');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 422) {
        final data = e.response?.data;
        final msg = data != null && data['message'] != null
            ? data['message'].toString()
            : 'Validasi gagal';
        throw Exception(msg);
      }
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  Future<void> forgotPassword(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'phone': phone},
      );
      if (response.statusCode == 200) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengirim permintaan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
