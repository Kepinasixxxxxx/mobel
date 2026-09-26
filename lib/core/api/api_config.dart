class ApiConfig {
  ApiConfig._();

  /// Works for web, desktop, and any Android device (emulator or physical)
  /// connected over USB with `adb reverse tcp:5000 tcp:5000` run once per
  /// connection — that forwards the device's `localhost:5000` to this PC's
  /// backend, so no IP juggling is needed.
  static const String origin = 'http://localhost:5000';

  static String get baseUrl => '$origin/api/v0/mobile';
}
