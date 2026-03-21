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
  await ApiAlerts.send(const Event(message: 'Deploy complete'));
}
```

## Usage

### Global singleton (recommended)

Call `configure` once at startup, then use `send` / `sendAsync` anywhere.

```dart
import 'package:apialerts/apialerts.dart';

void main() async {
  ApiAlerts.configure('your-api-key');

  // Fire-and-forget — never throws
  await ApiAlerts.send(const Event(message: 'Deploy complete'));

  // Or get the result back — also never throws
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
| `link`    | `String?`               | No       | URL attached to the notification |
| `data`    | `Map<String, dynamic>?` | No       | Arbitrary key-value metadata     |

```dart
const event = Event(
  message: 'Deploy complete',
  channel: 'releases',
  event: 'ci.deploy',
  title: 'Deployed',
  tags: ['CI/CD', 'Dart'],
  link: 'https://github.com/apialerts/apialerts-dart/actions',
  data: {'version': '2.0.0'},
);
```

### Instance-based client

Use `ApiAlertsClient` directly when you need multiple clients or want to
manage the lifecycle yourself.

```dart
import 'package:apialerts/apialerts.dart';

final client = ApiAlertsClient('your-api-key', debug: true);
final result = await client.sendAsync(const Event(message: 'Deploy complete'));
if (result.success) {
  print('Sent to ${result.workspace} (${result.channel})');
} else {
  print('Error: ${result.error}');
}
```

## Links

- [Documentation](https://apialerts.com/docs)
- [Sign up](https://apialerts.com)
- [GitHub Issues](https://github.com/apialerts/apialerts-dart/issues)
