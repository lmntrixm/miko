/// Build/runtime switches.
class AppConfig {
  /// Free launch: every chapter opens, downloads need no subscription, and subscription
  /// prompts are hidden. Turn paid mode on with `--dart-define=FREE_MODE=false`
  /// (and set `FREE_MODE=0` on the backend).
  static bool freeMode = const bool.fromEnvironment(
    'FREE_MODE',
    defaultValue: true,
  );
}
