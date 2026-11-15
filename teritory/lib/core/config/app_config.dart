class AppConfig {
  AppConfig._();

  /// Teritory Standalone Backend Base URL.
  /// Works directly on physical device with: `adb reverse tcp:4000 tcp:4000`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/v1',
  );

  /// WebSocket URL for real-time events (chat, trip waypoints, etc.)
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:4000',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
