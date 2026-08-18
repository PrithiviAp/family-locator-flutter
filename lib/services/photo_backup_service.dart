import 'package:dio/dio.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class PhotoBackupService {
  static const _lastSyncKey = 'photo_last_sync_epoch';

  static Future<int> backupNewPhotos({int maxPerRun = 20}) async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) return 0;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncEpoch = prefs.getInt(_lastSyncKey) ?? 0;
    final lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncEpoch);

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image, onlyAll: true);
    if (albums.isEmpty) return 0;

    final recent = await albums.first.getAssetListPaged(page: 0, size: maxPerRun * 2);
    final toUpload = recent.where((a) => a.createDateTime.isAfter(lastSync)).take(maxPerRun).toList();

    if (toUpload.isEmpty) return 0;

    final api = await ApiClient.create();
    var uploaded = 0;
    DateTime newestSeen = lastSync;

    for (final asset in toUpload) {
      final file = await asset.file;
      if (file == null) continue;
      try {
        final formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          'takenAt': asset.createDateTime.toUtc().toIso8601String(),
        });
        final resp = await api.dio.post('/api/photos', data: formData);
        if (resp.statusCode != null && resp.statusCode! < 300) {
          uploaded++;
          if (asset.createDateTime.isAfter(newestSeen)) newestSeen = asset.createDateTime;
        }
      } catch (_) {
        // Leave lastSync where it was so this photo is retried next run.
        continue;
      }
    }

    if (uploaded > 0) {
      await prefs.setInt(_lastSyncKey, newestSeen.millisecondsSinceEpoch);
    }
    return uploaded;
  }
}
