/// Dart client for the API Alerts notification platform.
///
/// Configure the [ApiAlerts] singleton once, then send from anywhere. For
/// dependency injection or multiple keys, construct an [ApiAlertsClient].
library;

export 'src/api_alerts.dart';
export 'src/client.dart' show ApiAlertsClient;
export 'src/event.dart';
export 'src/result.dart';
