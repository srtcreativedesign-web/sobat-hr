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

  // Credentials Keys
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  static Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _savedEmailKey, value: email);
      await _secureStorage.write(key: _savedPasswordKey, value: password);
    } catch (e) {
      await _secureStorage.deleteAll();
      await _secureStorage.write(key: _savedEmailKey, value: email);
      await _secureStorage.write(key: _savedPasswordKey, value: password);
    }
  }

  static Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: _savedEmailKey);
      final password = await _secureStorage.read(key: _savedPasswordKey);
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
    } catch (e) {
      // Ignore
    }
  }

  // Clear session data (token + user), but NOT remembered credentials
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }

  // --- Sobat Outlet Storage ---

  static const String _sobatOutletUidKey = 'sobatOutlet_device_uid';
  static const String _sobatOutletSecretKey = 'sobatOutlet_secret_key';

  static Future<void> saveSobatOutletData(String deviceUid, String secretKey) async {
    try {
      await _secureStorage.write(key: _sobatOutletUidKey, value: deviceUid);
      await _secureStorage.write(key: _sobatOutletSecretKey, value: secretKey);
    } catch (e) {
      await _secureStorage.deleteAll();
      await _secureStorage.write(key: _sobatOutletUidKey, value: deviceUid);
      await _secureStorage.write(key: _sobatOutletSecretKey, value: secretKey);
    }
  }

  static Future<Map<String, String>?> getSobatOutletData() async {
    try {
      final uid = await _secureStorage.read(key: _sobatOutletUidKey);
      final secret = await _secureStorage.read(key: _sobatOutletSecretKey);
      if (uid != null && secret != null) {
        return {'device_uid': uid, 'secret_key': secret};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearSobatOutletData() async {
    try {
      await _secureStorage.delete(key: _sobatOutletUidKey);
      await _secureStorage.delete(key: _sobatOutletSecretKey);
    } catch (e) {
      // Ignore
    }
  }
}
