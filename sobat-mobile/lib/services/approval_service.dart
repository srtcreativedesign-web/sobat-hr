import 'package:dio/dio.dart';
import '../config/dio_factory.dart';
import 'auth_service.dart';
import '../utils/error_handler.dart';

class ApprovalService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

  ApprovalService() {
    _dio = DioFactory.create();
  }

  Future<List<dynamic>> getPendingApprovals() async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        'approvals/pending',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        } else if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception('Gagal memuat data persetujuan');
      }
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveRequest(
    int requestId,
    String signatureBase64,
  ) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.post(
        'requests/$requestId/approve',
        data: {'signature': signatureBase64},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectRequest(
    int requestId,
    String reason,
  ) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.post(
        'requests/$requestId/reject',
        data: {'reason': reason},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }
}
