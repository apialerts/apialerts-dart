import 'dart:io';

import 'package:apialerts/apialerts.dart';

Future<void> main(List<String> args) async {
  // Accept --build, --release, or --publish flags (ignored at runtime;
  // present so the script can be invoked via CI with those arguments).
  final validFlags = {'--build', '--release', '--publish'};
  for (final arg in args) {
    if (!validFlags.contains(arg)) {
      stderr.writeln('Unknown flag: $arg');
      exit(1);
    }
  }

  final apiKey = Platform.environment['APIALERTS_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('APIALERTS_API_KEY not set');
    exit(1);
  }

  ApiAlerts.configure(apiKey, debug: true);

  // Minimal send — message only
  final minimalResult = await ApiAlerts.sendAsync(
    const Event(message: 'Dart SDK - minimal'),
  );
  if (!minimalResult.success) {
    stderr.writeln('Error (minimal): ${minimalResult.error}');
    exit(1);
  }

  // Full send — all fields
  final fullResult = await ApiAlerts.sendAsync(
    const Event(
      message: 'Dart SDK - full',
      channel: 'developer',
      event: 'sdk.test',
      title: 'Integration Test',
      tags: ['CI/CD', 'Dart'],
      link: 'https://github.com/apialerts/apialerts-dart/actions',
      data: {'version': '2.0.0'},
    ),
  );
  if (!fullResult.success) {
    stderr.writeln('Error (full): ${fullResult.error}');
    exit(1);
  }
}
