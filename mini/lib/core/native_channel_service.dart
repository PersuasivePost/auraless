import 'dart:async';

import 'package:flutter/services.dart';

class NativeChannelService {
  static const MethodChannel _appChannel = MethodChannel('app_channel');
  static const MethodChannel _packageChannel = MethodChannel('package_channel');
  static const MethodChannel _batteryChannel = MethodChannel('battery_channel');
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

  // Package change events stream
  final StreamController<Map<String, String>> _packageStreamController =
      StreamController.broadcast();

  NativeChannelService() {
    _packageChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPackageChanged') {
        final args = call.arguments as Map?;
        if (args != null) {
          final event = args['event']?.toString() ?? '';
          final pkg = args['packageName']?.toString() ?? '';
          _packageStreamController.add({'event': event, 'packageName': pkg});
        }
      }
    });
  }

  Stream<Map<String, String>> get packageEvents =>
      _packageStreamController.stream;

  Future<bool> launchApp(String packageName) async {
    final res = await _appChannel.invokeMethod('launchApp', packageName);
    return res == true;
  }

  Future<bool> openDialer(String number) async {
    final res = await _appChannel.invokeMethod('openDialer', number);
    return res == true;
  }

  Future<bool> openUrl(String url) async {
    final res = await _appChannel.invokeMethod('openUrl', url);
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

  Future<List<Map<String, String>>> searchContacts(String query) async {
    final List<dynamic> raw = await _contactsChannel.invokeMethod(
      'searchContacts',
      query,
    );
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map(
          (m) => Map<String, String>.from(
            m.map((k, v) => MapEntry(k.toString(), v.toString())),
          ),
        )
        .toList();
  }

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
      'accessibility_check_channel',
    ).invokeMethod('isAccessibilityServiceEnabled');
    return res == true;
  }

  Future<void> openAccessibilitySettings() async {
    await MethodChannel(
      'accessibility_check_channel',
    ).invokeMethod('openAccessibilitySettings');
  }

  Future<void> openHomePicker() async {
    await _appChannel.invokeMethod('openHomePicker');
  }

  Future<void> setMindfulDelaySeconds(int seconds) async {
    await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('setMindfulDelaySeconds', seconds);
  }

  Future<int> getMindfulDelaySeconds() async {
    final res = await MethodChannel(
      'blocked_apps_channel',
    ).invokeMethod('getMindfulDelaySeconds');
    return (res is int) ? res : int.parse(res.toString());
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

  Future<bool> isGrayscaleEnabled() async {
    try {
      final res = await _grayChannel.invokeMethod('isGrayscaleEnabled');
      return res == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotificationDigest() async {
    final List<dynamic> raw = await MethodChannel(
      'notification_channel',
    ).invokeMethod('getNotificationDigest');
    return raw
        .cast<Map<dynamic, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> clearNotificationDigest() async {
    await MethodChannel(
      'notification_channel',
    ).invokeMethod('clearNotificationDigest');
  }

  Future<void> addEssentialPackage(String packageName) async {
    await MethodChannel(
      'notification_channel',
    ).invokeMethod('addEssentialPackage', packageName);
  }

  Future<void> removeEssentialPackage(String packageName) async {
    await MethodChannel(
      'notification_channel',
    ).invokeMethod('removeEssentialPackage', packageName);
  }

  Future<List<String>> getEssentialPackages() async {
    final List<dynamic> raw = await MethodChannel(
      'notification_channel',
    ).invokeMethod('getEssentialPackages');
    return raw.cast<String>().toList();
  }

  Future<void> openNotificationListenerSettings() async {
    await MethodChannel(
      'notification_channel',
    ).invokeMethod('openNotificationListenerSettings');
  }

  Future<bool> isNotificationListenerEnabled() async {
    final res = await MethodChannel(
      'notification_channel',
    ).invokeMethod('isNotificationListenerEnabled');
    return res == true;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final res = await _batteryChannel.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      return res == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    await _batteryChannel.invokeMethod('openBatteryOptimizationSettings');
  }
}
