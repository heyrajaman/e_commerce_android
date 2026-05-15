import 'dart:developer' as developer; // PROD FIX: Secure logging

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  StorageService(this._secureStorage, this._prefs);

  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  // --- Secure Storage (Sensitive Data) ---

  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e, stack) {
      developer.log(
        'Secure storage write failed',
        error: e,
        stackTrace: stack,
        name: 'StorageService',
      );
      // Keystore might be corrupted; wipe it to attempt recovery
      await _secureStorage.deleteAll();
      await _secureStorage.write(key: _tokenKey, value: token);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e, stack) {
      developer.log(
        'Secure storage read failed (Possible Keystore Invalidation)',
        error: e,
        stackTrace: stack,
        name: 'StorageService',
      );
      // PROD CRASH FIX: Wipe corrupted storage and return null to force a clean re-login
      await _secureStorage.deleteAll();
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e, stack) {
      developer.log(
        'Secure storage delete failed',
        error: e,
        stackTrace: stack,
        name: 'StorageService',
      );
    }
  }

  // --- Shared Preferences (Non-Sensitive Data) ---

  Future<void> saveUserRole(String role) async {
    await _prefs.setString(_roleKey, role);
  }

  String? getUserRole() {
    return _prefs.getString(_roleKey);
  }

  // --- User ID Storage ---

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  // SONARQUBE FIX: Made synchronous to match getUserRole and underlying SharedPreferences behavior
  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  // --- Utility ---

  /// Clears all local data (used during logout or unauthorized errors)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e, stack) {
      developer.log(
        'Failed to clear secure storage',
        error: e,
        stackTrace: stack,
        name: 'StorageService',
      );
    } finally {
      // Ensure preferences are cleared even if secure storage fails
      await _prefs.clear();
    }
  }
}
