import 'package:apialerts/src/constants.dart' as constants;
import 'package:test/test.dart';

/// Pins the wire-level constants to literal values. Guards against an
/// accidental endpoint change, a dropped timeout, or a stray bump to v2.
void main() {
  test('integration name is dart', () {
    expect(constants.integrationName, 'dart');
  });

  test('api url is the production endpoint', () {
    expect(constants.apiUrl, 'https://api.apialerts.com/event');
  });

  test('timeout is 30 seconds', () {
    expect(constants.timeoutSeconds, 30);
  });

  test('version is major 1.x', () {
    expect(
      constants.integrationVersion,
      matches(RegExp(r'^1\.\d+\.\d+(?:[-+][\w.]+)?$')),
    );
  });
}
