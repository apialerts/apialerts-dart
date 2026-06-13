import 'dart:io';

import 'package:apialerts/apialerts.dart';

Future<void> main(List<String> args) async {
  final channelIdx = args.indexOf('--channel');
  final channel = channelIdx >= 0 && channelIdx + 1 < args.length
      ? args[channelIdx + 1]
      : 'testing';

  final isBuild = args.contains('--build');
  final isRelease = args.contains('--release');
  final isPublish = args.contains('--publish');
  final isIntegrationTests = args.contains('--integration-tests');

  final apiKey = Platform.environment['APIALERTS_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('APIALERTS_API_KEY not set');
    exit(1);
  }

  ApiAlerts.configure(apiKey, debug: true);

  final link = 'https://github.com/apialerts/apialerts-dart/actions';

  if (isBuild) {
    final result = await ApiAlerts.sendAsync(Event(
      message: 'Dart SDK - PR build success',
      channel: 'developer',
      event: 'ci.build',
      title: 'Build Passed',
      tags: const ['CI/CD', 'Dart', 'Build'],
      link: link,
      data: const {'integration': 'dart'},
    ));
    if (!result.success) {
      stderr.writeln('Error: ${result.error}');
      exit(1);
    }
    stdout.writeln('✓ Sent to ${result.workspace} (${result.channel})');
  } else if (isRelease) {
    final result = await ApiAlerts.sendAsync(Event(
      message: 'Dart SDK - Build for publish success',
      channel: 'developer',
      event: 'ci.release',
      title: 'Release Build Passed',
      tags: const ['CI/CD', 'Dart', 'Build'],
      link: link,
      data: const {'integration': 'dart'},
    ));
    if (!result.success) {
      stderr.writeln('Error: ${result.error}');
      exit(1);
    }
    stdout.writeln('✓ Sent to ${result.workspace} (${result.channel})');
  } else if (isPublish) {
    final result = await ApiAlerts.sendAsync(Event(
      message: 'Dart SDK - pub.dev publish success',
      channel: 'releases',
      event: 'ci.publish',
      title: 'Published',
      tags: const ['CI/CD', 'Dart', 'Deploy'],
      link: link,
      data: const {'integration': 'dart'},
    ));
    if (!result.success) {
      stderr.writeln('Error: ${result.error}');
      exit(1);
    }
    stdout.writeln('✓ Sent to ${result.workspace} (${result.channel})');
  } else if (isIntegrationTests) {
    final minimalResult = await ApiAlerts.sendAsync(
      Event(message: 'Dart SDK - minimal', channel: channel),
    );
    if (!minimalResult.success) {
      stderr.writeln('Error (minimal): ${minimalResult.error}');
      exit(1);
    }
    stdout.writeln(
        '✓ sent to ${minimalResult.workspace} (${minimalResult.channel})');

    // Full send: all fields
    final fullResult = await ApiAlerts.sendAsync(
      Event(
        message: 'Dart SDK - full',
        channel: channel,
        event: 'sdk.test',
        title: 'Integration Test',
        tags: const ['CI/CD', 'Dart'],
        link: link,
        data: const {'integration': 'dart'},
      ),
    );
    if (!fullResult.success) {
      stderr.writeln('Error (full): ${fullResult.error}');
      exit(1);
    }
    stdout.writeln('✓ sent to ${fullResult.workspace} (${fullResult.channel})');
  } else {
    stderr.writeln(
        'Error: pass --build, --release, --publish, or --integration-tests');
    exit(1);
  }
}
