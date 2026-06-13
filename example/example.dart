import 'package:apialerts/apialerts.dart';

Future<void> main() async {
  ApiAlerts.configure('your-api-key');

  // Fire-and-forget.
  ApiAlerts.send(const Event(message: 'Deploy complete'));

  // Or await the result.
  final result = await ApiAlerts.sendAsync(const Event(
    message: 'New user signed up',
    channel: 'revenue',
    event: 'user.signup',
    title: 'New Signup',
    tags: ['growth'],
    link: 'https://dashboard.example.com/users/123',
    data: {'plan': 'pro'},
  ));
  print(result.success
      ? 'Sent to ${result.workspace} (${result.channel})'
      : 'Failed: ${result.error}');

  // Instance client, for DI or multiple keys.
  ApiAlertsClient('your-api-key').send(const Event(message: 'From a client'));
}
