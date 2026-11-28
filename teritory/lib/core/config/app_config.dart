class AppConfig {
  AppConfig._();

  /// Teritory Standalone Backend Base URL (Live Render Cloud Deployment).
  /// Can be overridden at build/run time via `--dart-define=API_BASE_URL=http://127.0.0.1:4000/v1`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://teritory-api.onrender.com/v1',
  );

  /// WebSocket URL for real-time events (chat, trip waypoints, etc.)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://teritory-api.onrender.com',
  );

  /// Origin that serves `/uploads/...`. The API base URL includes the `/v1`
  /// path, so it cannot be used directly for static media.
  static String get mediaOrigin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// Uploads are stored and returned as server-relative paths
  /// (`/uploads/<id>.jpg`). Widgets need an absolute URL; absolute URLs are
  /// passed through unchanged so externally hosted images keep working.
  static String resolveMediaUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '$mediaOrigin$trimmed';
    return '$mediaOrigin/$trimmed';
  }

  // Generous timeout to accommodate Render free-tier cold starts.
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0+1';
}
