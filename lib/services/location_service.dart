import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class LocationService {
  static const _queueKey = 'location_queue';

  /// Captures one fix. Returns null (and leaves it to the caller to have
  /// already notified the user) if GPS is off or permission isn't granted —
  /// never silently retries in a way the user can't see via the status UI.
  static Future<Position?> captureOnce() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> queuePosition(Position pos) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracyMeters': pos.accuracy,
      'speed': pos.speed,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
    }));
    // Cap the offline queue so a phone offline for days doesn't grow unbounded.
    final trimmed = queue.length > 500 ? queue.sublist(queue.length - 500) : queue;
    await prefs.setStringList(_queueKey, trimmed);
  }

  /// Sends every queued point in one batch call. Only clears the queue on a
  /// confirmed 2xx — anything else (network still down, device paused) keeps
  /// the points queued for the next sync attempt.
  static Future<bool> flushQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    if (queue.isEmpty) return true;

    final points = queue.map((s) => jsonDecode(s)).toList();
    final api = await ApiClient.create();
    try {
      final resp = await api.dio.post('/api/location', data: {'points': points});
      if (resp.statusCode != null && resp.statusCode! < 300) {
        await prefs.setStringList(_queueKey, []);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
