# API Alerts • Dart Client

[![pub.dev](https://img.shields.io/pub/v/apialerts)](https://pub.dev/packages/apialerts)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[pub.dev](https://pub.dev/packages/apialerts) • [GitHub](https://github.com/apialerts/apialerts-dart) • [API Alerts](https://apialerts.com)

Effortless project notifications. Send once, deliver everywhere.

## Installation

```yaml
dependencies:
  apialerts: 1.0.0
```

## Quick Start

```dart
import 'package:apialerts/apialerts.dart';

void main() async {
  ApiAlerts.configure('your-api-key');
  ApiAlerts.send(const Event(message: 'Deploy complete'));
}
```

## Usage

### Global singleton (recommended)

Call `configure` once at startup, then use `send` / `sendAsync` anywhere.

```dart
import 'package:apialerts/apialerts.dart';

void main() async {
  ApiAlerts.configure('your-api-key');

  // Fire-and-forget, never throws
  ApiAlerts.send(const Event(message: 'Deploy complete'));

  // Or get the result back, also never throws
  final result = await ApiAlerts.sendAsync(const Event(message: 'Deploy complete'));
  if (result.success) {
    print('Sent to ${result.workspace} (${result.channel})');
    for (final w in result.warnings) {
      print('Warning: $w');
    }
  } else {
    print('Error: ${result.error}');
  }
}
```

### Event fields

Only `message` is required. All other fields are optional.

| Field     | Type                    | Required | Description                      |
|-----------|-------------------------|----------|----------------------------------|
| `message` | `String`                | Yes      | Main notification message        |
| `channel` | `String?`               | No       | Target channel name              |
| `event`   | `String?`               | No       | Event key for routing            |
| `title`   | `String?`               | No       | Short title                      |
| `tags`    | `List<String>?`         | No       | Categorisation tags              |
| `link`    | `String?`               | No       | URL associated with the event (deeplink + CTA) |
| `data`    | `Map<String, dynamic>?` | No       | Arbitrary key-value metadata     |

```dart
const event = Event(
  message: 'Deploy complete',
  channel: 'releases',
  event: 'ci.deploy',
  title: 'Deployed',
  tags: ['CI/CD', 'Dart'],
  link: 'https://github.com/apialerts/apialerts-dart/actions',
  data: {'version': '1.4.2', 'commit': 'a1b2c3d'},
);
```

### Dependency injection

The `ApiAlerts` singleton is the quickest way to send. When you want DI, mocking
in tests, or multiple keys side by side, construct an `ApiAlertsClient` directly.
`ApiAlerts` is a thin facade over a default `ApiAlertsClient`, so the two never
drift.

```dart
import 'package:apialerts/apialerts.dart';

final client = ApiAlertsClient('your-api-key');
client.send(const Event(message: 'Deploy complete'));
```

Register it with your service locator (for example `get_it`) and depend on the
type. In tests, supply your own implementation of `ApiAlertsClient`.

### Send to a different workspace

Pass an optional `apiKey` to override the configured key for a single call.

```dart
ApiAlerts.send(event, apiKey: 'other-workspace-key');

final result = await ApiAlerts.sendAsync(event, apiKey: 'other-workspace-key');
```

## Platform support

Runs on Android, iOS, web, macOS, Windows, and Linux.

- **Android:** add the INTERNET permission to `android/app/src/main/AndroidManifest.xml`. Flutter only adds it for debug builds, so release builds fail without it:

  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

- **macOS:** add the network client entitlement to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements` so requests pass the app sandbox:

  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```

- **Web:** works in the browser, but your API key ships in the app bundle and is visible to anyone who inspects it. Only use a key you are comfortable exposing client-side.
- **iOS, Windows, Linux:** no extra configuration. The endpoint is HTTPS, so iOS App Transport Security is satisfied by default.

## Links

- [Documentation](https://apialerts.com/docs)
- [Sign up](https://apialerts.com)
- [GitHub Issues](https://github.com/apialerts/apialerts-dart/issues)
