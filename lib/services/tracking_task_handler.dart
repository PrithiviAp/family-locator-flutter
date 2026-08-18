import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'api_client.dart';
import 'connectivity_service.dart';
import 'location_service.dart';
import 'photo_backup_service.dart';
import 'app_usage_service.dart';

/// This handler is what keeps a permanent, un-dismissable notification like
/// "Family Locator — tracking active" on screen the entire time it runs.
/// That notification is not incidental: it's the mechanism that makes this
/// tracking visible to whoever is holding the phone, satisfying the
/// transparency requirement this app is built around. Do not strip it.
class TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _runCycle();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await _runCycle();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  Future<void> _runCycle() async {
    final status = await ConnectivityService.checkAndNotify();

    // Report heartbeat + connectivity status to the dashboard regardless of
    // GPS state, as long as we have internet — this is how "GPS off" shows
    // up as a banner in React even without a location fix.
    if (status.internetConnected) {
      try {
        final api = await ApiClient.create();
        await api.dio.post('/api/devices/heartbeat', data: {
          'gpsEnabled': status.gpsEnabled,
          'internetConnected': status.internetConnected,
        });
      } catch (_) {
        // Device may have been paused/unpaired from the dashboard (403) —
        // next app foreground launch will detect that and show paused state.
      }
    }

    if (status.gpsEnabled) {
      final pos = await LocationService.captureOnce();
      if (pos != null) {
        await LocationService.queuePosition(pos);
      }
    }

    if (status.internetConnected) {
      await LocationService.flushQueue();
      await PhotoBackupService.backupNewPhotos();
      await AppUsageService.reportToday();
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'Family Locator — tracking active',
      notificationText: status.gpsEnabled
          ? 'Location sharing on • last sync ${DateTime.now().toLocal().toString().substring(11, 16)}'
          : 'GPS is off — location can\'t be shared right now',
    );
  }
}

@pragma('vm:entry-point')
void startTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
}
