import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const tokenKey = 'auth_token';

  static const demoEmails = {
    'patient': 'alice@health.test',
    'doctor': 'sarah.chen@health.test',
    'admin': 'admin@health.test',
  };

  static const demoPassword = 'password';
}
