import 'package:dio/dio.dart';
import '../config/dio_factory.dart';
import 'auth_service.dart';

class EmployeeService {
  late final Dio _dio;
  final AuthService _authService = AuthService();

  EmployeeService() {
    _dio = DioFactory.create();
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        'employees',
        queryParameters: {'search': query, 'per_page': 10},
      );

      if (response.statusCode == 200) {
        final body = response.data;
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
      return [];
    }
  }
}
