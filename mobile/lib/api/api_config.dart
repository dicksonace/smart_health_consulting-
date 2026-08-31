import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Live Hostinger API (same server as WedPlan, separate app path).
  /// Set to false only when testing a local Laravel server.
  static const bool useLiveApi = true;

  /// Does not touch marriageplan.site WedPlan routes — Health lives under /smart-health.
  static const String liveHost = 'https://marriageplan.site/smart-health';

  static String get baseUrl => '$assetBaseUrl/api';

  static String get mediaBaseUrl => assetBaseUrl;

  static String get assetBaseUrl {
    if (useLiveApi) return liveHost;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static const tokenKey = 'auth_token';

  static const demoEmails = {
    'patient': 'alice@health.test',
    'doctor': 'sarah.chen@health.test',
    'admin': 'admin@health.test',
  };

  static const demoPassword = 'password';
}
