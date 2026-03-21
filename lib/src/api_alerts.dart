import 'dart:io';

import 'package:http/http.dart' as http;

import 'client.dart';
import 'event.dart';
import 'result.dart';

/// Global singleton facade for the API Alerts client.
///
/// Call [configure] once at startup, then use [send] or [sendAsync] anywhere.
///
/// ```dart
/// void main() async {
///   ApiAlerts.configure('your-api-key');
///   await ApiAlerts.send(Event(message: 'Deploy complete'));
/// }
/// ```
class ApiAlerts {
  ApiAlerts._();

  static ApiAlertsClient? _instance;

  /// Initialise the global client. Subsequent calls are no-ops.
  static void configure(
    String apiKey, {
    bool debug = false,
    http.Client? httpClient,
  }) {
    _instance ??= ApiAlertsClient(apiKey, debug: debug, httpClient: httpClient);
  }

  /// Override the integration name, version, and base URL on the global client.
  ///
  /// No-op if [configure] has not been called yet.
  static void setOverrides(String integration, String version, String baseUrl) {
    _instance?.setOverrides(integration, version, baseUrl);
  }

  /// Send an event — fire-and-forget. Never throws.
  ///
  /// Silently does nothing if the global client has not been initialised.
  static Future<void> send(Event event) async {
    await _instance?.send(event);
  }

  /// Send an event and return the result. Never throws.
  ///
  /// Returns [SendResult] with [SendResult.success] `false` and an [SendResult.error]
  /// message if the client has not been initialised or delivery fails.
  /// Check [SendResult.success] to determine whether the event was delivered.
  static Future<SendResult> sendAsync(Event event) async {
    if (_instance == null) {
      stderr.writeln('x (apialerts.com) Error: client not configured');
      return const SendResult(success: false, error: 'client not configured');
    }
    return _instance!.sendAsync(event);
  }

  // ignore: invalid_use_of_visible_for_testing_member
  /// Resets the global client. For use in tests only.
  static void reset() => _instance = null;
}
