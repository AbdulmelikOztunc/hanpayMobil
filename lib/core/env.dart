abstract final class Env {
  /// `dev` → Somee test sunucusu, `prod` → canlı API, `local` → yerel backend.
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const _someeApiUrl = 'https://turkmenpay.somee.com/api';
  static const _prodApiUrl = 'https://api.hanpay.com.tr/api';
  static const _localApiUrl = 'http://10.0.2.2:5000/api';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return switch (appEnv) {
      'prod' => _prodApiUrl,
      'local' => _localApiUrl,
      _ => _someeApiUrl,
    };
  }

  static bool get isDev => appEnv != 'prod';
  static bool get isProd => appEnv == 'prod';

  static String get environmentLabel => switch (appEnv) {
        'prod' => 'Production',
        'local' => 'Local',
        _ => 'Somee Test',
      };

  static String get hubOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String get notificationsHubUrl => '$hubOrigin/hubs/notifications';

  /// Uploaded files (receipts etc.) — same origin as API without `/api` suffix.
  static String assetUrl(String path) {
    final clean = path.replaceFirst(RegExp(r'^/+'), '');
    return '$hubOrigin/$clean';
  }
}
