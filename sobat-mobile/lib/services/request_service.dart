import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class RequestService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  RequestService() {
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

  // Get Leave Balance & Eligibility
  Future<Map<String, dynamic>> getLeaveBalance() async {
    await _addAuthHeader();
    try {
      final response = await _dio.get('/requests/leave-balance');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Gagal mengambil data saldo cuti';
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Submit Request
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> data) async {
    await _addAuthHeader();
    try {
      final response = await _dio.post('/requests', data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint(
        '❌ Create Request Error: ${e.response?.statusCode} - ${e.response?.data}',
      );
      throw e.response?.data['message'] ?? 'Gagal mengirim pengajuan';
    } catch (e) {
      debugPrint('❌ General Error: $e');
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Get Requests List
  Future<List<dynamic>> getRequests({String? type, String? status}) async {
    await _addAuthHeader();
    try {
      final response = await _dio.get(
        '/requests',
        queryParameters: {
          if (type != null) 'type': type,
          if (status != null && status != 'Semua') 'status': status,
        },
      );
      // Assuming paginated response or list?
      // Controller returns paginate(20). So data is in 'data'.
      return response.data['data'];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Gagal mengambil data pengajuan';
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }
}
