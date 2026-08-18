import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'tracking_task_handler.dart';

class TrackingManager {
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static Future<void> _configure() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'family_locator_tracking',
        channelName: 'Family Locator Tracking',
        channelDescription: 'Shown continuously while location/photo sync is active.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // Deliberately NOT ongoing-dismiss-suppressed beyond Android defaults —
        // the person holding the phone should always be able to see this.
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5 * 60 * 1000), // every 5 min
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    await _configure();
    if (await FlutterForegroundTask.isRunningService) return true;

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Family Locator — tracking active',
      notificationText: 'Starting up…',
      callback: startTrackingCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;
}
