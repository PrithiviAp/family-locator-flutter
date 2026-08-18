import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// These are LOCAL notifications shown on the tracked phone itself — part of
/// what makes this transparent rather than covert. If GPS or internet drops,
/// the person holding the phone sees it too, not just the dashboard.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> show({required int id, required String title, required String body}) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'family_locator_alerts',
      'Family Locator Alerts',
      channelDescription: 'GPS and internet status changes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  static Future<void> gpsOff() =>
      show(id: 101, title: 'GPS turned off', body: 'Location can\'t be shared until GPS is back on.');

  static Future<void> gpsOn() => show(id: 102, title: 'GPS turned on', body: 'Location sharing resumed.');

  static Future<void> internetOff() =>
      show(id: 103, title: 'No internet connection', body: 'Location/photos will sync once back online.');

  static Future<void> internetOn() =>
      show(id: 104, title: 'Back online', body: 'Syncing queued location and photo updates.');
}
