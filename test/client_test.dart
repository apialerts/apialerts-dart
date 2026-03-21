import 'dart:convert';

import 'package:apialerts/apialerts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

http.Response successResponse({
  String workspace = 'My Workspace',
  String channel = 'general',
  List<String> warnings = const [],
}) =>
    http.Response(
      jsonEncode({'workspace': workspace, 'channel': channel, 'warnings': warnings}),
      200,
      headers: {'content-type': 'application/json'},
    );

ApiAlertsClient clientWith(http.Client mock, {String apiKey = 'test-key'}) =>
    ApiAlertsClient(apiKey, httpClient: mock);

// ── Validation ────────────────────────────────────────────────────────────────

void main() {
  group('validation', () {
    test('returns error result when message is empty', () async {
      final client = clientWith(MockClient((_) async => successResponse()));
      final result = await client.sendAsync(const Event(message: ''));
      expect(result.success, isFalse);
      expect(result.error, 'message is required');
    });

    test('returns error result when api key is empty', () async {
      final client = clientWith(MockClient((_) async => successResponse()), apiKey: '');
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'api key is missing');
    });
  });

  // ── HTTP status codes ───────────────────────────────────────────────────────

  group('HTTP status codes', () {
    test('200 returns successful SendResult', () async {
      final client = clientWith(
        MockClient((_) async => successResponse(workspace: 'W', channel: 'C')),
      );
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.workspace, 'W');
      expect(result.channel, 'C');
      expect(result.warnings, isEmpty);
    });

    test('200 with warnings populates warnings list', () async {
      final client = clientWith(
        MockClient((_) async =>
            successResponse(warnings: ['This channel will be deprecated soon'])),
      );
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.warnings, hasLength(1));
      expect(result.warnings.first, 'This channel will be deprecated soon');
    });

    test('400 returns error result with bad request message', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 400)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'bad request');
    });

    test('401 returns error result with unauthorized message', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 401)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'unauthorized — check your api key');
    });

    test('403 returns error result with forbidden message', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 403)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'forbidden');
    });

    test('429 returns error result with rate limit message', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 429)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'rate limit exceeded');
    });

    test('500 returns error result with unexpected status message', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 500)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'unexpected status: 500');
    });

    test('invalid JSON response returns error result', () async {
      final client = clientWith(MockClient((_) async => http.Response('not json', 200)));
      final result = await client.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'invalid response from server');
    });
  });

  // ── Request headers ─────────────────────────────────────────────────────────

  group('request headers', () {
    test('sends Authorization header', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendAsync(const Event(message: 'test'));
      expect(captured.headers['Authorization'], 'Bearer test-key');
    });

    test('sends Content-Type header', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendAsync(const Event(message: 'test'));
      expect(captured.headers['Content-Type'], contains('application/json'));
    });

    test('sends X-Integration and X-Version headers', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendAsync(const Event(message: 'test'));
      expect(captured.headers['X-Integration'], 'dart');
      expect(captured.headers['X-Version'], '2.0.0');
    });

    test('setOverrides changes integration headers', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      client.setOverrides('github-actions', '1.0.0', 'http://localhost');
      await client.sendAsync(const Event(message: 'test'));
      expect(captured.headers['X-Integration'], 'github-actions');
      expect(captured.headers['X-Version'], '1.0.0');
    });

    test('sendWithKey uses the provided key', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendWithKey('override-key', const Event(message: 'test'));
      expect(captured.headers['Authorization'], 'Bearer override-key');
    });
  });

  // ── Payload serialization ────────────────────────────────────────────────────

  group('payload', () {
    test('sends full event payload', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendAsync(const Event(
        message: 'Full payload',
        channel: 'developer',
        event: 'ci.deploy',
        title: 'Deployed',
        tags: ['CI/CD', 'Dart'],
        link: 'https://github.com',
        data: {'version': '2.0.0'},
      ));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['message'], 'Full payload');
      expect(body['channel'], 'developer');
      expect(body['event'], 'ci.deploy');
      expect(body['title'], 'Deployed');
      expect(body['tags'], ['CI/CD', 'Dart']);
      expect(body['link'], 'https://github.com');
      expect(body['data'], {'version': '2.0.0'});
    });

    test('null fields are omitted from payload', () async {
      late http.Request captured;
      final client = clientWith(MockClient((req) async {
        captured = req;
        return successResponse();
      }));
      await client.sendAsync(const Event(message: 'minimal'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('channel'), isFalse);
      expect(body.containsKey('event'), isFalse);
      expect(body.containsKey('title'), isFalse);
      expect(body.containsKey('tags'), isFalse);
      expect(body.containsKey('link'), isFalse);
      expect(body.containsKey('data'), isFalse);
    });
  });

  // ── Fire-and-forget ──────────────────────────────────────────────────────────

  group('send (fire-and-forget)', () {
    test('does not throw on error', () async {
      final client = clientWith(MockClient((_) async => http.Response('', 401)));
      await expectLater(
        client.send(const Event(message: 'test')),
        completes,
      );
    });
  });

  // ── Global singleton ─────────────────────────────────────────────────────────

  group('ApiAlerts singleton', () {
    setUp(() => ApiAlerts.reset());
    tearDown(() => ApiAlerts.reset());

    test('sendAsync returns error result before configure', () async {
      final result = await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'client not configured');
    });

    test('configure initialises the client', () async {
      final mock = MockClient((_) async => successResponse());
      ApiAlerts.configure('key', httpClient: mock);
      final result = await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.workspace, 'My Workspace');
    });

    test('configure is idempotent — second call is a no-op', () async {
      int callCount = 0;
      final mock = MockClient((_) async {
        callCount++;
        return successResponse();
      });
      ApiAlerts.configure('first-key', httpClient: mock);
      ApiAlerts.configure('second-key'); // should be ignored
      await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(callCount, 1); // only one HTTP call, not two
    });

    test('send is a no-op before configure', () async {
      await expectLater(
        ApiAlerts.send(const Event(message: 'test')),
        completes,
      );
    });
  });
}
