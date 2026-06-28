import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows real local notifications (e.g. when a new swap match is made).
/// Entirely on-device — no push/FCM backend involved.
class NotificationService {
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  int _id = 1000;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _fln.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> show({required String title, required String body}) async {
    if (!_ready) await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'matches_channel',
        'Matches & messages',
        channelDescription: 'Swap matches and chat alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _fln.show(_id++, title, body, details);
  }

  Future<void> showMatch(String otherName) => show(
        title: "It's a Swap Match! 🎉",
        body: 'You and $otherName both want to swap. Tap to start chatting.',
      );
}
