# Changelog

## 1.0.0

First stable release.

- `ApiAlerts` global singleton: call `configure()` once, then `send()` anywhere
- `ApiAlertsClient` instance client for dependency injection, multiple keys, or mocking
- `Event` model with required `message` and optional `channel`, `event`, `title`, `tags`, `link`, and `data`
- `send()`: fire-and-forget, never throws
- `sendAsync()`: returns a `SendResult` for callers that need delivery confirmation
- Per-call `apiKey` override on both send methods
- 30-second request timeout
- Runs on Android, iOS, web, macOS, Windows, and Linux (WASM-ready)
- Debug mode logs delivery confirmations and warnings; critical errors always log

## 1.0.0-alpha.1

Initial alpha release of the API Alerts Dart client.
