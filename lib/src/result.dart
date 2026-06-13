/// The result of an event delivery attempt.
///
/// Check [success] to determine whether the event was delivered.
/// On success, [workspace] and [channel] are populated.
/// On failure, [error] contains a human-readable error message.
class SendResult {
  final bool success;
  final String? workspace;
  final String? channel;
  final List<String> warnings;
  final String? error;

  const SendResult({
    required this.success,
    this.workspace,
    this.channel,
    this.warnings = const [],
    this.error,
  });
}
