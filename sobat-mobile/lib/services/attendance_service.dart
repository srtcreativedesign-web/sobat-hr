import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';

class AttendanceService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AttendanceService() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
  }

  Future<void> _addAuthHeader() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _dio.options.headers['Accept'] = 'application/json';
  }

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required File photo,
    required String status, // 'present', 'late', etc.
    String? notes,
  }) async {
    await _addAuthHeader();

    try {
      // Get current user to get employee_id (Assuming Profile endpoint or stored)
      // Ideally employee_id should be stored in Session/Provider, but for now fetch 'me' or assume backend handles it?
      // Wait, AttendanceController 'store' requires 'employee_id'.
      // Usually AuthController 'me' returns employee data including ID.
      // Let's first fetch user profile if we don't have ID.
      // OR, we can update "store" method in backend to use Auth::user()->employee->id if not provided?
      // Checking backend... store requires 'employee_id'.
      // I will assume we can get it from AuthProvider or Me endpoint.
      // To keep it simple, let's fetch /auth/me first inside here or expect caller to pass it.
      // Better: Fetch /auth/me short cache.

      final userResponse = await _dio.get(ApiConfig.profile);
      final employeeId = userResponse.data['employee']['id'];

      String fileName = photo.path.split('/').last;

      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'check_in': DateFormat('HH:mm:ss').format(DateTime.now()),
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/attendances', // ApiConfig.attendance might be different, let's use direct path or update Config
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ??
          'Gagal melakukan absensi: ${e.message}';
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    await _addAuthHeader();
    try {
      // Use standard endpoint
      final response = await _dio.get('/attendance/today');

      // If response data is empty or null, return null (Belum Absen)
      if (response.data == null || response.data.toString().isEmpty) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // Not found
      // If error is something else, maybe silence it or throw
      print('Error fetching today attendance: ${e.message}');
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getHistory({int? month, int? year}) async {
    await _addAuthHeader();
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get(
        '/attendance/history',
        queryParameters: queryParams,
      );

      return response.data as List<dynamic>;
    } catch (e) {
      throw 'Gagal memuat riwayat absensi: $e';
    }
  }
}
