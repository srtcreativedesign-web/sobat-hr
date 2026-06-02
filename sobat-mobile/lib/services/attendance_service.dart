import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';
import 'base_service.dart';

class AttendanceService extends BaseService {
  Future<Map<String, dynamic>> checkIn({
    required int employeeId,
    required double latitude,
    required double longitude,
    required File photo,
    required String status,
    String? address,
    String? notes,
    String? attendanceType,
    String? fieldNotes,
    String? trackType,
    bool? isShifting,
    String? shiftStartTime,
    String? shiftEndTime,
    String? qrCodeData,
  }) async {
    

    try {
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

      if (notes != null && notes.isNotEmpty) map['notes'] = notes;
      if (attendanceType != null) map['attendance_type'] = attendanceType;
      if (trackType != null) map['track_type'] = trackType;
      if (isShifting != null) map['is_shifting'] = isShifting ? 1 : 0;
      if (fieldNotes != null && fieldNotes.isNotEmpty) {
        map['field_notes'] = fieldNotes;
      }
      if (shiftStartTime != null) map['shift_start_time'] = shiftStartTime;
      if (shiftEndTime != null) map['shift_end_time'] = shiftEndTime;
      if (qrCodeData != null && qrCodeData.isNotEmpty) {
        map['qr_code_data'] = qrCodeData;
      }

      FormData formData = FormData.fromMap(map);

      final response = await dio.post(ApiConfig.attendance, data: formData);

      return response.data;
    } on DioException catch (e) {
      // Parse server error message (e.g. maintenance 503, geolocation 422)
      final serverMessage = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      if (serverMessage != null) {
        throw serverMessage;
      }
      rethrow;
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    
    try {
      final response = await dio.get(ApiConfig.attendanceToday);

      if (response.data == null ||
          response.data.toString().isEmpty ||
          (response.data is Map && response.data.isEmpty) ||
          (response.data is List && response.data.isEmpty)) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getHistory({int? month, int? year}) async {
    
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await dio.get(
        'attendance/history',
        queryParameters: queryParams,
      );

      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  /// Get unclosed attendance records (forgot to checkout)
  /// Returns records from last 3 days that have check_in but no check_out
  Future<List<dynamic>> getUnclosedAttendance() async {
    try {
      final response = await dio.get('attendance/unclosed');
      final data = response.data;
      return data is List ? data : [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      debugPrint('Failed to fetch unclosed attendance: $e');
      return [];
    } catch (e) {
      debugPrint('Error fetching unclosed attendance: $e');
      return [];
    }
  }

  /// Resolve QR code to outlet/organization info
  Future<Map<String, dynamic>?> resolveQrCode(String qrCode) async {
    try {
      final response = await dio.get(
        ApiConfig.resolveQr,
        queryParameters: {'qr_code': qrCode},
      );
      return response.data;
    } catch (e) {
      debugPrint('QR resolve error: $e');
      return null;
    }
  }

  /// Fetch all configured attendance locations from server
  Future<List<Map<String, dynamic>>> getAttendanceLocations() async {
    try {
      final response = await dio.get(ApiConfig.attendanceLocations);
      final locations = response.data['locations'] as List;
      return locations.map((loc) => Map<String, dynamic>.from(loc)).toList();
    } catch (e) {
      debugPrint('Failed to fetch attendance locations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required int attendanceId,
    required String checkOutTime,
    required File photo,
    String? status,
    String? notes,
    String? attendanceType,
    String? fieldNotes,
  }) async {

    try {
      String fileName = photo.path.split('/').last;

      Map<String, dynamic> map = {
        '_method': 'PUT',
        'check_out': checkOutTime,
        'status': status,
        'notes': notes,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      };

      if (attendanceType != null) map['attendance_type'] = attendanceType;
      if (fieldNotes != null) map['field_notes'] = fieldNotes;

      FormData formData = FormData.fromMap(map);

      final response = await dio.post(
        'attendances/$attendanceId',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      if (serverMessage != null) {
        throw serverMessage;
      }
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }
}
