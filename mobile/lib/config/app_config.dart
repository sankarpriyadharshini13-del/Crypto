import 'package:flutter/foundation.dart';


class AppConfig {
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }

  static String get wsUrl {
    final u = Uri.parse(apiBaseUrl);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    return u.replace(scheme: scheme, path: '/ws').toString();
  }
}
