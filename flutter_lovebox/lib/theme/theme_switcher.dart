import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeSwitcher with ChangeNotifier {
  static bool _isDark = false;
  static final ThemeSwitcher instance = ThemeSwitcher._privateConstructor();

  ThemeSwitcher._privateConstructor() {
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    _isDark = brightness == Brightness.dark;
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void switchTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setTheme(bool dark) {
    _isDark = dark;
    notifyListeners();
  }
}
