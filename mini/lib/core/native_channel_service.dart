import 'dart:async';

import 'package:flutter/services.dart';

class NativeChannelService {
  static const MethodChannel _appChannel = MethodChannel('app_channel');
  static const MethodChannel _sysChannel = MethodChannel('system_info_channel');
  static const MethodChannel _usageChannel = MethodChannel(
    'usage_stats_channel',
  );
  static const MethodChannel _grayChannel = MethodChannel('grayscale_channel');
  static const MethodChannel _contactsChannel = MethodChannel(
    'contacts_channel',
  );

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final List<dynamic> raw = await _appChannel.invokeMethod(
      'getInstalledApps',
    );
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<bool> launchApp(String packageName) async {
    final res = await _appChannel.invokeMethod('launchApp', packageName);
    return res == true;
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final Map<dynamic, dynamic> raw = await _sysChannel.invokeMethod(
      'getSystemInfo',
    );
    return Map<String, dynamic>.from(raw);
  }

  // placeholders
  Future<dynamic> usagePlaceholder() async =>
      await _usageChannel.invokeMethod('placeholder');
  Future<dynamic> grayscalePlaceholder() async =>
      await _grayChannel.invokeMethod('placeholder');
  Future<dynamic> contactsPlaceholder() async =>
      await _contactsChannel.invokeMethod('placeholder');

  // Usage stats
  Future<List<Map<String, dynamic>>> getUsageStats(
    DateTime start,
    DateTime end,
  ) async {
    final args = {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    };
    final List<dynamic> raw = await _usageChannel.invokeMethod(
      'getUsageStats',
      args,
    );
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<bool> hasUsageStatsPermission() async {
    final res = await _usageChannel.invokeMethod('hasUsagePermission');
    return res == true;
  }

  Future<void> requestUsageStatsPermission() async {
    await _usageChannel.invokeMethod('requestUsagePermission');
  }

  // Blocked apps management
  Future<void> addBlockedApp(String packageName) async {
    await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('addBlockedApp', packageName);
  }

  Future<void> removeBlockedApp(String packageName) async {
    await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('removeBlockedApp', packageName);
  }

  Future<List<String>> getBlockedApps() async {
    final List<dynamic> raw = await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('getBlockedApps');
    return raw.cast<String>().toList();
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    final res = await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('isAccessibilityServiceEnabled');
    return res == true;
  }

  Future<void> openAccessibilitySettings() async {
    await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('openAccessibilitySettings');
  }

  Future<bool> enableGrayscale() async {
    try {
      final res = await _grayChannel.invokeMethod('enableGrayscale');
      return res == true;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') return false;
      rethrow;
    }
  }

  Future<bool> disableGrayscale() async {
    try {
      final res = await _grayChannel.invokeMethod('disableGrayscale');
      return res == true;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') return false;
      rethrow;
    }
  }
}
