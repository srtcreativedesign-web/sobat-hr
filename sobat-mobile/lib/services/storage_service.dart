import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  // Token Management (Secure Storage)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  // User Data Management (Shared Preferences)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
  }
  
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return json.decode(userString) as Map<String, dynamic>;
    }
    return null;
  }
  
  static Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
