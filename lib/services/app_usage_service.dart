import 'package:app_usage/app_usage.dart';
import 'api_client.dart';

/// Reports ONLY aggregate per-app minutes for today — the same ceiling every
/// mainstream parental-control app uses. Never touches notification text,
/// message content, or screenshots.
class AppUsageService {
  static Future<void> reportToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    List<AppUsageInfo> infos;
    try {
      infos = await AppUsage().getAppUsage(startOfDay, now);
    } catch (_) {
      return; // permission not granted yet — UI should prompt via Settings deep link
    }

    final items = infos
        .where((i) => i.usage.inSeconds > 0)
        .map((i) => {
              'packageName': i.packageName,
              'appName': i.appName.isNotEmpty ? i.appName : i.packageName,
              'foregroundMinutes': (i.usage.inSeconds / 60).round(),
            })
        .toList();

    if (items.isEmpty) return;

    final api = await ApiClient.create();
    final dateStr = '${startOfDay.year.toString().padLeft(4, '0')}-'
        '${startOfDay.month.toString().padLeft(2, '0')}-'
        '${startOfDay.day.toString().padLeft(2, '0')}';

    try {
      await api.dio.post('/api/app-usage', data: {'date': dateStr, 'items': items});
    } catch (_) {
      // Will retry on next periodic run; no local queue needed since the
      // next report always re-sends the full running total for today.
    }
  }
}
