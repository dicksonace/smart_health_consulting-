import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class TokenStorage {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> read() async {
    try {
      final token = await _secure.read(key: ApiConfig.tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}

    return (await SharedPreferences.getInstance()).getString(ApiConfig.tokenKey);
  }

  static Future<void> write(String token) async {
    try {
      await _secure.write(key: ApiConfig.tokenKey, value: token);
    } catch (_) {
      await (await SharedPreferences.getInstance()).setString(ApiConfig.tokenKey, token);
    }
  }

  static Future<void> clear() async {
    try {
      await _secure.delete(key: ApiConfig.tokenKey);
    } catch (_) {}
    await (await SharedPreferences.getInstance()).remove(ApiConfig.tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await read();
    return token != null && token.isNotEmpty;
  }
}
