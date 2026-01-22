import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String keyAppTitle = "app_title";
  static const String keyIsFirstTime = "is_first_time";

  Future<void> setAppTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAppTitle, title);
  }

  Future<String> getAppTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAppTitle) ?? "ThreadSocial";
  }

  Future<void> setFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsFirstTime, value);
  }

  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsFirstTime) ?? true;
  }
}
