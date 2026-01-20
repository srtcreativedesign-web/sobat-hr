import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class NotificationService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  NotificationService() {
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

  Future<List<Map<String, dynamic>>> getNotifications() async {
    await _addAuthHeader();
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error get notifications: $e');
      return [];
    }
  }

  Future<bool> markAsRead({String? id}) async {
    await _addAuthHeader();
    try {
      final response = await _dio.post('/notifications/read', data: {'id': id});
      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error mark as read: $e');
      return false;
    }
  }
}
