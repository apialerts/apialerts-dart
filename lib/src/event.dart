/// An event to send to API Alerts. Only [message] is required; null fields are
/// omitted from the payload.
class Event {
  /// Human-readable notification text. Required. Appears on the push lock screen.
  final String message;

  /// Workspace channel the push fires on. Defaults to the workspace default
  /// when omitted.
  final String? channel;

  /// What kind of thing happened. Optional but recommended. Use dotted notation
  /// (`ci.deploy.success`, `payment.failed`) so routing rules can glob-match
  /// (`ci.*`, `*.failed`).
  final String? event;

  /// Short headline some destinations render separately from the body.
  final String? title;

  /// Categorisation tags for filtering and search.
  final List<String>? tags;

  /// URL attached to the notification. Tapping the push opens it.
  final String? link;

  /// Arbitrary key-value metadata. Available to non-push destinations for
  /// templating.
  final Map<String, dynamic>? data;

  /// Creates an event. Only [message] is required.
  const Event({
    required this.message,
    this.channel,
    this.event,
    this.title,
    this.tags,
    this.link,
    this.data,
  });

  /// The request payload, with null fields omitted.
  Map<String, dynamic> toJson() => {
        'message': message,
        if (channel != null) 'channel': channel,
        if (event != null) 'event': event,
        if (title != null) 'title': title,
        if (tags != null) 'tags': tags,
        if (link != null) 'link': link,
        if (data != null) 'data': data,
      };
}
