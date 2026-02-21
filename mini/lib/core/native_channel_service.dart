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
}
