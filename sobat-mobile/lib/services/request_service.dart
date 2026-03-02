import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../config/dio_factory.dart';

class RequestService {
  late final Dio _dio;

  RequestService() {
    _dio = DioFactory.create();
  }

  Future<void> _addAuthHeader() async {
    final token = await StorageService.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    _dio.options.headers['Accept'] = 'application/json';
  }

  // Get Leave Balance & Eligibility
  Future<Map<String, dynamic>> getLeaveBalance() async {
    await _addAuthHeader();
    try {
      final response = await _dio.get(
        'requests/leave-balance',
      ); // Removed leading slash
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
      final response = await _dio.post(
        'requests',
        data: data,
      ); // Removed leading slash
      return response.data;
    } on DioException catch (e) {
      // debugPrint(
      // '❌ Create Request Error: ${e.response?.statusCode} - ${e.response?.data}',
      // );
      throw e.response?.data['message'] ?? 'Gagal mengirim pengajuan';
    } catch (e) {
      // debugPrint('❌ General Error: $e');
      throw 'Terjadi kesalahan: $e';
    }
  }

  // Get Requests List
  Future<List<dynamic>> getRequests({String? type, String? status}) async {
    await _addAuthHeader();
    try {
      final response = await _dio.get(
        'requests', // Removed leading slash
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
