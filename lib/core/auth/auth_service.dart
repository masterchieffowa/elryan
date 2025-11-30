import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const String _passwordKey = 'user_password';
  static const String _defaultPassword = 'admin123';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_passwordKey)) {
      await setPassword(_defaultPassword);
    }
  }

  Future<bool> login(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey);
    final inputHash = _hashPassword(password);
    return storedHash == inputHash;
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPassword(password);
    await prefs.setString(_passwordKey, hash);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}