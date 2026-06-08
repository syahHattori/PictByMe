import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);
  static const _key = 'settings_dark_mode';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_key) ?? false;
    isDark.value = v;
  }

  static Future<void> setDark(bool v) async {
    isDark.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
  }
}
