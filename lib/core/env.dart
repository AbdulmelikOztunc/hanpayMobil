abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.hanpay.com.tr/api',
  );

  static String get hubOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String get notificationsHubUrl => '$hubOrigin/hubs/notifications';
}
