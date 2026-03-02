import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'storage_service.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../config/dio_factory.dart';

class AttendanceService {
  late final Dio _dio;

  AttendanceService() {
    _dio = DioFactory.create();
  }

  Future<void> _addAuthHeader() async {
    final token = await StorageService.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _dio.options.headers['Accept'] = 'application/json';
  }

  Future<Map<String, dynamic>> checkIn({
    required int employeeId,
    required double latitude,
    required double longitude,
    required File photo,
    required String status, // 'present', 'late', etc.
    String? address, // Added address
    String? notes,
    String? attendanceType,
    String? fieldNotes,
  }) async {
    await _addAuthHeader();

    try {
      // Use passed employeeId instead of fetching it

      String fileName = photo.path.split('/').last;

      final map = <String, dynamic>{
        'employee_id': employeeId,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'check_in': DateFormat('HH:mm:ss').format(DateTime.now()),
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'location_address': address ?? '',
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      };

      // Only add optional fields if they have values (avoid sending "null" string)
      if (notes != null && notes.isNotEmpty) map['notes'] = notes;
      if (attendanceType != null) map['attendance_type'] = attendanceType;
      if (fieldNotes != null && fieldNotes.isNotEmpty) {
        map['field_notes'] = fieldNotes;
      }

      FormData formData = FormData.fromMap(map);

      final response = await _dio.post(ApiConfig.attendance, data: formData);

      return response.data;
    } on DioException catch (e) {
      String errorMessage = 'Gagal melakukan absensi';
      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      }

      if (errorMessage == 'Gagal melakukan absensi' && e.message != null) {
        errorMessage += ': ${e.message}';
      }
      throw errorMessage;
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    await _addAuthHeader();
    try {
      // Use standard endpoint
      final response = await _dio.get(ApiConfig.attendanceToday);

      // If response data is empty or null, return null (Belum Absen)
      if (response.data == null ||
          response.data.toString().isEmpty ||
          (response.data is Map && response.data.isEmpty) ||
          (response.data is List && response.data.isEmpty)) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // Not found
      // If error is something else, maybe silence it or throw
      // print('Error fetching today attendance: ${e.message}');
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
        'attendance/history', // No leading slash
        queryParameters: queryParams,
      );

      return response.data as List<dynamic>;
    } catch (e) {
      throw 'Gagal memuat riwayat absensi: $e';
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required int attendanceId,
    required String checkOutTime,
    required File photo,
    String? status,
    String? notes,
  }) async {
    await _addAuthHeader();
    try {
      String fileName = photo.path.split('/').last;

      // Use FormData to allow file upload
      // Laravel requires POST with _method=PUT to handle multipart/form-data for updates
      FormData formData = FormData.fromMap({
        '_method': 'PUT',
        'check_out': checkOutTime,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        'attendances/$attendanceId', // Manual path without leading slash
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      String errorMessage = 'Gagal melakukan check-out';
      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      }

      if (errorMessage == 'Gagal melakukan check-out' && e.message != null) {
        errorMessage += ': ${e.message}';
      }
      throw errorMessage;
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }
}
