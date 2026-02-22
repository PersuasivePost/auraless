import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:auraless/core/hive_service.dart';
import 'package:auraless/constants/colors.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeMode _mode = AppThemeMode.system;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _load() {
    final raw = HiveService.getSetting('theme_mode', defaultValue: 'system');
    if (raw == 'light') {
      _mode = AppThemeMode.light;
    } else if (raw == 'dark') {
      _mode = AppThemeMode.dark;
    } else {
      _mode = AppThemeMode.system;
    }
  }

  AppThemeMode get mode => _mode;

  bool get isSystem => _mode == AppThemeMode.system;

  Brightness get systemBrightness =>
      PlatformDispatcher.instance.platformBrightness;

  bool get isDarkMode {
    if (_mode == AppThemeMode.light) return false;
    if (_mode == AppThemeMode.dark) return true;
    return systemBrightness == Brightness.dark;
  }

  AppColors get colors => isDarkMode ? AppColors.dark : AppColors.light;

  Future<void> setThemeMode(AppThemeMode m) async {
    _mode = m;
    await HiveService.setSetting(
      'theme_mode',
      m == AppThemeMode.light
          ? 'light'
          : (m == AppThemeMode.dark ? 'dark' : 'system'),
    );
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
