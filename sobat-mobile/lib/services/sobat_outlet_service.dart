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

  /// Get Outlet Attendance History
  Future<List<dynamic>> getHistory(String deviceUid, String secretKey, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await dio.get('/sobat-outlet/history', 
        queryParameters: queryParams,
        options: Options(
          headers: {
            'x-device-uid': deviceUid,
            'x-secret-key': secretKey,
          }
        )
      );
      return response.data['data'] ?? [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil riwayat absensi.');
    }
  }

  /// Download PDF History
  Future<void> downloadPdf(String deviceUid, String secretKey, String savePath, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      await dio.download('/sobat-outlet/history/pdf', savePath, 
        queryParameters: queryParams,
        options: Options(
          headers: {
            'x-device-uid': deviceUid,
            'x-secret-key': secretKey,
          }
        )
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengunduh PDF.');
    }
  }

  /// Download Excel History
  Future<void> downloadExcel(String deviceUid, String secretKey, String savePath, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      await dio.download('/sobat-outlet/history/excel', savePath, 
        queryParameters: queryParams,
        options: Options(
          headers: {
            'x-device-uid': deviceUid,
            'x-secret-key': secretKey,
          }
        )
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengunduh Excel.');
    }
  }
}
