import 'package:dio/dio.dart';
import '../services/base_service.dart';

class SobatOutletService extends BaseService {
  
  /// Get all available outlets
  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      final response = await dio.get('/organizations', queryParameters: {
        'type': 'branch',
      });
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch outlets');
    }
  }

  /// Auto-register Sobat Outlet device (deprecated but kept for compatibility)
  Future<Map<String, dynamic>> autoRegister({
    required int organizationId,
    required String deviceUid,
    required String deviceName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.post('/sobat-outlet/auto-register', data: {
        'organization_id': organizationId,
        'device_uid': deviceUid,
        'device_name': deviceName,
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to register Sobat Outlet');
    }
  }

  /// Login as Outlet Device using Code and PIN
  Future<Map<String, dynamic>> login({
    required String deviceCode,
    required String pin,
    required String deviceUid,
  }) async {
    try {
      final response = await dio.post('/sobat-outlet/login', data: {
        'device_code': deviceCode,
        'pin': pin,
        'device_uid': deviceUid,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal login outlet.');
    }
  }
}
