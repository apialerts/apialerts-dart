import 'dart:convert';

import 'package:http/http.dart' as http;

import 'console.dart';
import 'constants.dart' as constants;
import 'event.dart';
import 'result.dart';

/// An API Alerts client. Construct one directly for DI, multiple keys, or
/// mocking; otherwise use the [ApiAlerts] singleton.
class ApiAlertsClient {
  /// The API key sent as the bearer token on every request.
  final String apiKey;

  /// When true, successful sends and HTTP errors are logged. Critical errors
  /// (missing key, empty message) always log regardless.
  final bool debug;

  final http.Client _httpClient;

  String _integration = constants.integrationName;
  String _integrationVersion = constants.integrationVersion;
  String _baseUrl = constants.apiUrl;

  /// Creates a client bound to [apiKey]. Pass `debug: true` to log delivery.
  ApiAlertsClient(
    this.apiKey, {
    this.debug = false,
  }) : _httpClient = http.Client();

  /// Override the integration name, version, and base URL.
  ///
  /// Used by official integrations and in tests to redirect requests to a
  /// mock server.
  void setOverrides(String integration, String version, String baseUrl) {
    _integration = integration;
    _integrationVersion = version;
    _baseUrl = baseUrl;
  }

  /// Sends an event, fire-and-forget. Never throws.
  ///
  /// Critical errors (missing key, empty message) are always printed to
  /// stderr. HTTP errors and success are only printed when [debug] is enabled.
  void send(Event event, {String? apiKey}) {
    // ignore: unawaited_futures
    _sendInternal(event, apiKey: apiKey);
  }

  Future<void> _sendInternal(Event event, {String? apiKey}) async {
    final key = (apiKey != null && apiKey.isNotEmpty) ? apiKey : this.apiKey;
    if (key.isEmpty) {
      consoleError('x (apialerts.com) Error: api key is missing');
      return;
    }
    if (event.message.isEmpty) {
      consoleError('x (apialerts.com) Error: message is required');
      return;
    }

    final result = await sendAsync(event, apiKey: apiKey);
    if (!debug) return;

    if (!result.success) {
      consoleError('x (apialerts.com) Error: ${result.error}');
    } else {
      consoleLog(
          '✓ (apialerts.com) Alert sent to ${result.workspace} (${result.channel})');
      for (final w in result.warnings) {
        consoleLog('! (apialerts.com) Warning: $w');
      }
    }
  }

  /// Sends an event and returns the result. Never throws.
  Future<SendResult> sendAsync(Event event, {String? apiKey}) {
    final key = (apiKey != null && apiKey.isNotEmpty) ? apiKey : this.apiKey;
    return _post(key, event);
  }

  Future<SendResult> _post(String key, Event event) async {
    if (key.isEmpty) {
      return const SendResult(success: false, error: 'api key is missing');
    }
    if (event.message.isEmpty) {
      return const SendResult(success: false, error: 'message is required');
    }

    try {
      final response = await _httpClient
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              'X-Integration': _integration,
              'X-Version': _integrationVersion,
            },
            body: jsonEncode(event.toJson()),
          )
          .timeout(const Duration(seconds: constants.timeoutSeconds));

      switch (response.statusCode) {
        case 200:
          final Map<String, dynamic> body;
          try {
            body = jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {
            return const SendResult(
                success: false, error: 'invalid response from server');
          }
          final workspace = body['workspace'] as String?;
          final channel = body['channel'] as String?;
          final warnings = (body['warnings'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          return SendResult(
            success: true,
            workspace: workspace,
            channel: channel,
            warnings: warnings,
          );

        case 400:
          return const SendResult(success: false, error: 'bad request');
        case 401:
          return const SendResult(
              success: false, error: 'unauthorized, check your api key');
        case 403:
          return const SendResult(success: false, error: 'forbidden');
        case 429:
          return const SendResult(success: false, error: 'rate limit exceeded');
        default:
          return SendResult(
              success: false,
              error: 'unexpected status: ${response.statusCode}');
      }
    } catch (e) {
      return SendResult(success: false, error: e.toString());
    }
  }
}
