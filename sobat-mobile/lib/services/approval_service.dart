import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApprovalService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getPendingApprovals() async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/approvals/pending',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Handle pagination or direct list
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        } else if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception('Failed to load approvals');
      }
    } catch (e) {
      throw Exception('Error loading approvals: $e');
    }
  }

  Future<Map<String, dynamic>> approveRequest(
    int requestId,
    String signatureBase64,
  ) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/requests/$requestId/approve',
        data: {'signature': signatureBase64},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to approve request',
        );
      }
      throw Exception('Error approving request: $e');
    }
  }

  Future<Map<String, dynamic>> rejectRequest(
    int requestId,
    String reason,
  ) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/requests/$requestId/reject',
        data: {'reason': reason},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          e.response?.data['message'] ?? 'Failed to reject request',
        );
      }
      throw Exception('Error rejecting request: $e');
    }
  }
}
