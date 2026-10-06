/// Build/runtime switches.
class AppConfig {
  /// Backend base URL (e.g. https://api.[domain]). Empty = built-in mock data.
  static const apiUrl = String.fromEnvironment('API_URL');
  static bool get useApi => apiUrl.isNotEmpty;

  /// Free launch: every chapter opens, downloads need no subscription, and subscription
  /// prompts are hidden. Turn paid mode on with `--dart-define=FREE_MODE=false`
  /// (and set `FREE_MODE=0` on the backend).
  static bool freeMode = const bool.fromEnvironment(
    'FREE_MODE',
    defaultValue: true,
  );
}
