import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AnnouncementService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getAnnouncements({
    String? category,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No auth token found');

    var url = '${ApiConfig.baseUrl}/announcements';
    if (category != null) {
      url += '?category=$category';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load announcements: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAnnouncement(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/announcements/$id'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load announcement details');
    }
  }
}
