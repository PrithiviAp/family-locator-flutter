import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps every request with the device's pairing key (x-device-key), which is
/// set once during onboarding after the owner pairs this phone from the
/// React dashboard. This key can be revoked from the dashboard at any time —
/// server then returns 403 and the app must stop syncing and show "paused".
class ApiClient {
  static const _baseUrlKey = 'api_base_url';
  static const _deviceKeyKey = 'device_key';

  late final Dio dio;

  ApiClient._(this.dio);

static Future<ApiClient> create() async {
  final prefs = await SharedPreferences.getInstance();

  final baseUrl = 'https://family-locator-api-1.onrender.com';

  final deviceKey = prefs.getString(_deviceKeyKey);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  if (deviceKey != null) {
    dio.options.headers['x-device-key'] = deviceKey;
  }

  return ApiClient._(dio);
}

  static Future<void> saveConfig({required String baseUrl, required String deviceKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    await prefs.setString(_deviceKeyKey, deviceKey);
  }

  static Future<bool> isPaired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceKeyKey) != null;
  }
}
