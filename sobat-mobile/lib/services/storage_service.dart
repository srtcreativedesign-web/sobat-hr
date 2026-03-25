import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Token Management (Secure Storage)
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      // If keystore is deeply corrupted, clear all secure storage and try again
      await _secureStorage.deleteAll();
      await _secureStorage.write(key: _tokenKey, value: token);
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      // Handle PlatformException containing BadPaddingException
      // This happens when the Android Keystore changes or encryptedSharedPreferences flag is toggled
      await _secureStorage.deleteAll();
      return null;
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      // Ignore if cannot delete
    }
  }

  // User Data Management (Secure Storage — contains PII)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      await _secureStorage.write(key: _userKey, value: json.encode(user));
    } catch (e) {
      await _secureStorage.deleteAll();
      await _secureStorage.write(key: _userKey, value: json.encode(user));
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final userString = await _secureStorage.read(key: _userKey);
      if (userString != null) {
        return json.decode(userString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      await _secureStorage.deleteAll();
      return null;
    }
  }

  static Future<void> deleteUser() async {
    try {
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      // Ignore if cannot delete
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
