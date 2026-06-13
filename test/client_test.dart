import 'dart:convert';
import 'dart:io';

import 'package:apialerts/apialerts.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late int port;

  // Per-test response configuration
  int responseStatus = 200;
  Map<String, dynamic> responseBody = {};
  String? rawBody;

  // Per-test request capture
  Request? lastRequest;
  String lastRequestBody = '';
  int requestCount = 0;

  setUpAll(() async {
    server = await shelf_io.serve(
      (request) async {
        lastRequest = request;
        lastRequestBody = await request.readAsString();
        requestCount++;
        return Response(
          responseStatus,
          body: rawBody ?? jsonEncode(responseBody),
          headers: {'content-type': 'application/json'},
        );
      },
      'localhost',
      0,
    );
    port = server.port;
  });

  tearDownAll(() async => server.close(force: true));

  setUp(() {
    responseStatus = 200;
    responseBody = {
      'workspace': 'My Workspace',
      'channel': 'general',
      'warnings': <String>[],
    };
    rawBody = null;
    lastRequest = null;
    lastRequestBody = '';
    requestCount = 0;
  });

  ApiAlertsClient makeClient({String apiKey = 'test-key'}) =>
      ApiAlertsClient(apiKey)
        ..setOverrides('dart', '1.0.0', 'http://localhost:$port/event');

  // Validation

  group('validation', () {
    test('returns error result when message is empty', () async {
      final result = await makeClient().sendAsync(const Event(message: ''));
      expect(result.success, isFalse);
      expect(result.error, 'message is required');
      expect(requestCount, 0);
    });

    test('returns error result when api key is empty', () async {
      final result =
          await makeClient(apiKey: '').sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'api key is missing');
      expect(requestCount, 0);
    });
  });

  // HTTP status codes

  group('HTTP status codes', () {
    test('200 returns successful SendResult', () async {
      responseBody = {
        'workspace': 'W',
        'channel': 'C',
        'warnings': <String>[],
      };
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.workspace, 'W');
      expect(result.channel, 'C');
      expect(result.warnings, isEmpty);
    });

    test('200 with warnings populates warnings list', () async {
      responseBody = {
        'workspace': 'W',
        'channel': 'C',
        'warnings': ['This channel will be deprecated soon'],
      };
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.warnings, hasLength(1));
      expect(result.warnings.first, 'This channel will be deprecated soon');
    });

    test('400 returns error result with bad request message', () async {
      responseStatus = 400;
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'bad request');
    });

    test('401 returns error result with unauthorized message', () async {
      responseStatus = 401;
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'unauthorized, check your api key');
    });

    test('403 returns error result with forbidden message', () async {
      responseStatus = 403;
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'forbidden');
    });

    test('429 returns error result with rate limit message', () async {
      responseStatus = 429;
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'rate limit exceeded');
    });

    test('500 returns error result with unexpected status message', () async {
      responseStatus = 500;
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'unexpected status: 500');
    });

    test('invalid JSON response returns error result', () async {
      rawBody = 'not json';
      final result = await makeClient().sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'invalid response from server');
    });
  });

  // Request headers

  group('request headers', () {
    test('sends Authorization header', () async {
      await makeClient().sendAsync(const Event(message: 'test'));
      expect(lastRequest!.headers['authorization'], 'Bearer test-key');
    });

    test('sends Content-Type header', () async {
      await makeClient().sendAsync(const Event(message: 'test'));
      expect(
          lastRequest!.headers['content-type'], contains('application/json'));
    });

    test('sends X-Integration and X-Version headers', () async {
      await makeClient().sendAsync(const Event(message: 'test'));
      expect(lastRequest!.headers['x-integration'], 'dart');
      expect(
        lastRequest!.headers['x-version'],
        matches(RegExp(r'^\d+\.\d+\.\d+')),
      );
    });

    test('setOverrides changes integration headers', () async {
      final client = ApiAlertsClient('test-key')
        ..setOverrides(
            'github-actions', '2.0.0', 'http://localhost:$port/event');
      await client.sendAsync(const Event(message: 'test'));
      expect(lastRequest!.headers['x-integration'], 'github-actions');
      expect(lastRequest!.headers['x-version'], '2.0.0');
    });

    test('sendAsync with apiKey uses the provided key', () async {
      await makeClient()
          .sendAsync(const Event(message: 'test'), apiKey: 'override-key');
      expect(lastRequest!.headers['authorization'], 'Bearer override-key');
    });
  });

  // Payload serialization

  group('payload', () {
    test('sends full event payload', () async {
      await makeClient().sendAsync(const Event(
        message: 'Full payload',
        channel: 'developer',
        event: 'ci.deploy',
        title: 'Deployed',
        tags: ['CI/CD', 'Dart'],
        link: 'https://github.com',
        data: {'version': '2.0.0'},
      ));
      final body = jsonDecode(lastRequestBody) as Map<String, dynamic>;
      expect(body['message'], 'Full payload');
      expect(body['channel'], 'developer');
      expect(body['event'], 'ci.deploy');
      expect(body['title'], 'Deployed');
      expect(body['tags'], ['CI/CD', 'Dart']);
      expect(body['link'], 'https://github.com');
      expect(body['data'], {'version': '2.0.0'});
    });

    test('null fields are omitted from payload', () async {
      await makeClient().sendAsync(const Event(message: 'minimal'));
      final body = jsonDecode(lastRequestBody) as Map<String, dynamic>;
      expect(body.containsKey('channel'), isFalse);
      expect(body.containsKey('event'), isFalse);
      expect(body.containsKey('title'), isFalse);
      expect(body.containsKey('tags'), isFalse);
      expect(body.containsKey('link'), isFalse);
      expect(body.containsKey('data'), isFalse);
    });
  });

  // Fire-and-forget

  group('send (fire-and-forget)', () {
    test('does not throw on error', () {
      responseStatus = 401;
      expect(
        () => makeClient().send(const Event(message: 'test')),
        returnsNormally,
      );
    });
  });

  // Global singleton

  group('ApiAlerts singleton', () {
    setUp(() => ApiAlerts.reset());
    tearDown(() => ApiAlerts.reset());

    test('sendAsync returns error result before configure', () async {
      final result = await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(result.success, isFalse);
      expect(result.error, 'client not configured');
    });

    test('configure initialises the client', () async {
      ApiAlerts.configure('key');
      ApiAlerts.setOverrides('dart', '1.0.0', 'http://localhost:$port/event');
      final result = await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(result.success, isTrue);
      expect(result.workspace, 'My Workspace');
    });

    test('configure is idempotent, second call is a no-op', () async {
      ApiAlerts.configure('first-key');
      ApiAlerts.setOverrides('dart', '1.0.0', 'http://localhost:$port/event');
      ApiAlerts.configure('second-key'); // should be ignored
      await ApiAlerts.sendAsync(const Event(message: 'test'));
      expect(lastRequest!.headers['authorization'], 'Bearer first-key');
    });

    test('send is a no-op before configure', () {
      expect(
        () => ApiAlerts.send(const Event(message: 'test')),
        returnsNormally,
      );
    });
  });
}
