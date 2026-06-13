import 'client.dart';
import 'console.dart';
import 'event.dart';
import 'result.dart';

/// Global singleton facade. Call [configure] once, then [send] or [sendAsync]
/// anywhere.
class ApiAlerts {
  ApiAlerts._();

  static ApiAlertsClient? _instance;

  /// Initialise the global client. Subsequent calls are no-ops.
  static void configure(
    String apiKey, {
    bool debug = false,
  }) {
    _instance ??= ApiAlertsClient(apiKey, debug: debug);
  }

  /// Override the integration name, version, and base URL on the global client.
  ///
  /// No-op if [configure] has not been called yet.
  static void setOverrides(String integration, String version, String baseUrl) {
    _instance?.setOverrides(integration, version, baseUrl);
  }

  /// Sends an event, fire-and-forget. Never throws.
  ///
  /// Silently does nothing if the global client has not been initialised.
  static void send(Event event, {String? apiKey}) {
    // ignore: unawaited_futures
    _instance?.send(event, apiKey: apiKey);
  }

  /// Sends an event and returns the result. Never throws.
  ///
  /// Check [SendResult.success]. Returns a failure result if [configure] was
  /// never called.
  static Future<SendResult> sendAsync(Event event, {String? apiKey}) async {
    if (_instance == null) {
      consoleError('x (apialerts.com) Error: client not configured');
      return const SendResult(success: false, error: 'client not configured');
    }
    return _instance!.sendAsync(event, apiKey: apiKey);
  }

  // ignore: invalid_use_of_visible_for_testing_member
  /// Resets the global client. For use in tests only.
  static void reset() => _instance = null;
}
