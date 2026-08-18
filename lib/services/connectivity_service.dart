import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class ConnectivityStatus {
  final bool gpsEnabled;
  final bool internetConnected;
  ConnectivityStatus({required this.gpsEnabled, required this.internetConnected});
}

class ConnectivityService {
  static const _prevGpsKey = 'prev_gps_status';
  static const _prevNetKey = 'prev_net_status';

  /// Reads current GPS + internet state, fires a local notification if either
  /// flipped since the last check, and returns the current status so callers
  /// can also report it to the server heartbeat endpoint.
  static Future<ConnectivityStatus> checkAndNotify() async {
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    final connectivityResult = await Connectivity().checkConnectivity();
    final internetConnected = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

    final prefs = await SharedPreferences.getInstance();
    final prevGps = prefs.getBool(_prevGpsKey);
    final prevNet = prefs.getBool(_prevNetKey);

    if (prevGps != null && prevGps != gpsEnabled) {
      gpsEnabled ? await NotificationService.gpsOn() : await NotificationService.gpsOff();
    }
    if (prevNet != null && prevNet != internetConnected) {
      internetConnected ? await NotificationService.internetOn() : await NotificationService.internetOff();
    }

    await prefs.setBool(_prevGpsKey, gpsEnabled);
    await prefs.setBool(_prevNetKey, internetConnected);

    return ConnectivityStatus(gpsEnabled: gpsEnabled, internetConnected: internetConnected);
  }
}
