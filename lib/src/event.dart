/// An event to send to the API Alerts platform.
///
/// Only [message] is required. All other fields are optional and omitted
/// from the JSON payload if null — equivalent to Go's `omitempty`.
///
/// ```dart
/// // Minimal
/// final event = Event(message: 'Deploy complete');
///
/// // Full
/// final event = Event(
///   message: 'Deploy complete',
///   channel: 'releases',
///   event: 'ci.deploy',
///   title: 'Deployed',
///   tags: ['CI/CD', 'Dart'],
///   link: 'https://github.com/apialerts/apialerts-dart/actions',
///   data: {'version': '2.0.0'},
/// );
/// ```
class Event {
  final String message;
  final String? channel;
  final String? event;
  final String? title;
  final List<String>? tags;
  final String? link;
  final Map<String, dynamic>? data;

  const Event({
    required this.message,
    this.channel,
    this.event,
    this.title,
    this.tags,
    this.link,
    this.data,
  });

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
