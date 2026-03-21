import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'event.dart';
import 'result.dart';

const _defaultBaseUrl = 'https://api.apialerts.com/event';
const _defaultIntegration = 'dart';
const _defaultVersion = '1.0.0';

/// An instance-based API Alerts client.
///
/// Use the static methods on [ApiAlerts] for a convenient global singleton,
/// or construct this class directly when you need multiple clients or want
/// full control over configuration.
class ApiAlertsClient {
  final String apiKey;
  final bool debug;
  final http.Client _httpClient;

  String _integration = _defaultIntegration;
  String _integrationVersion = _defaultVersion;
  String _baseUrl = _defaultBaseUrl;

  ApiAlertsClient(
    this.apiKey, {
    this.debug = false,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Override the integration name, version, and base URL.
  ///
  /// Used by official integrations and in tests to redirect requests to a
  /// mock server.
  void setOverrides(String integration, String version, String baseUrl) {
    _integration = integration;
    _integrationVersion = version;
    _baseUrl = baseUrl;
  }

  /// Send an event — fire-and-forget. Never throws.
  ///
  /// Critical errors (not configured, missing key, empty message) are always
  /// printed to stderr. HTTP errors and success are only printed when [debug]
  /// is enabled.
  Future<void> send(Event event) async {
    if (apiKey.isEmpty) {
      stderr.writeln('x (apialerts.com) Error: api key is missing');
      return;
    }
    if (event.message.isEmpty) {
      stderr.writeln('x (apialerts.com) Error: message is required');
      return;
    }

    final result = await sendAsync(event);
    if (!debug) return;

    if (!result.success) {
      stderr.writeln('x (apialerts.com) Error: ${result.error}');
    } else {
      // ignore: avoid_print
      print('✓ (apialerts.com) Alert sent to ${result.workspace} (${result.channel})');
      for (final w in result.warnings) {
        // ignore: avoid_print
        print('! (apialerts.com) Warning: $w');
      }
    }
  }

  /// Send an event and return the result. Never throws.
  ///
  /// Check [SendResult.success] to determine whether the event was delivered.
  Future<SendResult> sendAsync(Event event) => _post(apiKey, event);

  /// Send an event using an explicit API key, bypassing the configured one.
  Future<SendResult> sendWithKey(String key, Event event) => _post(key, event);

  Future<SendResult> _post(String key, Event event) async {
    if (key.isEmpty) {
      return const SendResult(success: false, error: 'api key is missing');
    }
    if (event.message.isEmpty) {
      return const SendResult(success: false, error: 'message is required');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
          'X-Integration': _integration,
          'X-Version': _integrationVersion,
        },
        body: jsonEncode(event.toJson()),
      );

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
              success: false, error: 'unauthorized — check your api key');
        case 403:
          return const SendResult(success: false, error: 'forbidden');
        case 429:
          return const SendResult(
              success: false, error: 'rate limit exceeded');
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
