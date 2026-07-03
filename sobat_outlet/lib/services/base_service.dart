import 'package:dio/dio.dart';
import '../config/dio_factory.dart';
import '../services/storage_service.dart';

/// Base service class that provides common functionality for all API services.
/// 
/// This class handles:
/// - Dio initialization with proper configuration
/// - Automatic token attachment to requests
/// - Auto logout on 401 responses
/// 
/// Extend this class for all your API services to avoid code duplication.
/// 
/// Example:
/// ```dart
/// class AuthService extends BaseService {
///   Future<Map<String, dynamic>> login(String email, String password) async {
///     final response = await _dio.post('auth/login', data: {...});
///     return response.data;
///   }
/// }
/// ```
abstract class BaseService {
  late final Dio _dio;

  /// Returns the Dio instance for making HTTP requests.
  /// 
  /// Subclasses should use this to make API calls.
  Dio get dio => _dio;

  BaseService() {
    _dio = DioFactory.create();
    _dio.interceptors.add(_authInterceptor());
  }

  /// Interceptor that automatically attaches auth token to requests
  /// and handles 401 responses by clearing storage.
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Auto logout if 401
        if (error.response?.statusCode == 401) {
          await StorageService.clearAll();
        }
        return handler.next(error);
      },
    );
  }
}
