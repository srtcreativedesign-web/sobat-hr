import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class AnnouncementService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? category,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Silakan login terlebih dahulu');

    var url = '${ApiConfig.baseUrl}${ApiConfig.announcements}';
    if (category != null) {
      url += '?category=$category';
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        }
        return List<Map<String, dynamic>>.from(jsonResponse);
      } else {
        throw Exception('Gagal memuat pengumuman');
      }
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getAnnouncement(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Silakan login terlebih dahulu');

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat detail pengumuman');
      }
    } catch (e) {
      throw Exception(AppErrorHandler.getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>?> fetchActiveAnnouncement() async {
    final token = await _authService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcementsActive}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
    } catch (e) {
      // Silent fail for active announcement (non-critical)
    }
    return null;
  }
}
