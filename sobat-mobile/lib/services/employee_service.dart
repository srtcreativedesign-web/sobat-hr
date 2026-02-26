import 'package:dio/dio.dart';
import '../config/dio_factory.dart';
import 'auth_service.dart';

class EmployeeService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

  EmployeeService() {
    _dio = DioFactory.create();
  }

  // Search employees by name or code
  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        'employees', // Use relative path
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
      // debugPrint('Error searching employees: $e');
      return [];
    }
  }
}
