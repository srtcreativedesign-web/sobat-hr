import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class EmployeeService {
  final Dio _dio = Dio();
  final AuthService _authService = AuthService();

  // Search employees by name or code
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/employees',
        queryParameters: {'search': query, 'per_page': 10}, // Limit results
      );

      if (response.statusCode == 200) {
        final body = response.data;
        // Handle pagination structure
        if (body is Map && body.containsKey('data')) {
          final list = body['data'] as List;
          return list.map((e) => e as Map<String, dynamic>).toList();
        } else if (body is List) {
          return body.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error searching employees: $e');
      return [];
    }
  }
}
