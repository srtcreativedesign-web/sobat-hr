import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'storage_service.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

import 'package:device_info_plus/device_info_plus.dart';

class AuthService extends BaseService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Debug logging
      debugPrint('=== LOGIN DEBUG ===');
      debugPrint('Base URL: ${ApiConfig.baseUrl}');
      debugPrint('Is Production: ${ApiConfig.isProduction}');
      debugPrint('Login endpoint: ${ApiConfig.login}');
      debugPrint('Full URL: ${ApiConfig.baseUrl}${ApiConfig.login}');
      
      String? deviceId;
      String? deviceName;
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
          deviceName = iosInfo.name;
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
        }
      } catch (e) {
        debugPrint('Failed to get device info: $e');
      }

      final response = await dio.post(
        ApiConfig.login,
        data: {
          'email': email, 
          'password': password,
          ?'device_id': deviceId,
          ?'device_name': deviceName,
        },
      );

      if (response.data is! Map) {
        throw Exception('Terjadi kesalahan pada server');
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await StorageService.saveToken(token);
        await StorageService.saveUser(userData);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      } else {
        throw Exception(AppErrorHandler.getErrorMessage(response.data));
      }
    } on DioException catch (e) {
      // Detailed error logging
      debugPrint('=== DIO ERROR ===');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('URI: ${e.requestOptions.uri}');
      debugPrint('Method: ${e.requestOptions.method}');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      if (e.error is SocketException) {
        debugPrint('Socket error: ${(e.error as SocketException).message}');
        debugPrint('OS error code: ${(e.error as SocketException).osError?.errorCode}');
        debugPrint('OS error message: ${(e.error as SocketException).osError?.message}');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      debugPrint('=== GENERAL ERROR ===');
      debugPrint('Error: $e');
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<User?> getProfile() async {
    try {
      final response = await dio.get(ApiConfig.profile);

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
      await dio.post(ApiConfig.logout);
    } catch (e) {
      // Ignore error, tetap clear local storage
    } finally {
      await StorageService.clearAll();
    }
  }

  Future<bool> checkAuth() async {
    final token = await StorageService.getToken();
    if (token == null) return false;

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
          ? dio.post('${ApiConfig.employees}/$id', data: payload)
          : dio.put('${ApiConfig.employees}/$id', data: payload));

      if (response.statusCode == 200) {
        await getProfile();
        return;
      }
      throw Exception('Gagal memperbarui data karyawan');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Data yang dimasukkan tidak valid');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> createEmployee(Object payload) async {
    try {
      final response = await dio.post(ApiConfig.employees, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await getProfile();
        return;
      }
      throw Exception('Gagal membuat data karyawan');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Data yang dimasukkan tidak valid');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>?> getSupervisorCandidate({
    required int organizationId,
    required String jobLevel,
    required String track,
  }) async {
    try {
      final response = await dio.get(
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
      final response = await dio.put(
        'auth/password',
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
      if (e.response?.statusCode == 422) {
        throw Exception('Password tidak valid');
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  Future<void> forgotPassword(String phone) async {
    try {
      final response = await dio.post(
        'auth/forgot-password',
        data: {'phone': phone},
      );
      if (response.statusCode == 200) {
        return;
      }
      throw Exception('Gagal mengirim permintaan');
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await dio.post(ApiConfig.fcmToken, data: {'fcm_token': token});
    } catch (e) {
      // Silently fail, not critical for app usage
    }
  }
}
