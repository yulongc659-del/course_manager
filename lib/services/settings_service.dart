import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static Future<Box> get _box async =>
      await Hive.openBox('settings');

  static Future<String> getApiKey() async {
    final box = await _box;
    return box.get('api_key', defaultValue: '') as String;
  }

  static Future<void> setApiKey(String key) async {
    final box = await _box;
    await box.put('api_key', key);
  }

  static Future<String> getBaseUrl() async {
    final box = await _box;
    return box.get('base_url', defaultValue: 'https://api.deepseek.com') as String;
  }

  static Future<void> setBaseUrl(String url) async {
    final box = await _box;
    await box.put('base_url', url);
  }
}
