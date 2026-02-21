import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'package:auraless/core/hive_service.dart';

class AppsProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<Map<String, dynamic>> _apps = [];
  bool _loading = false;

  AppsProvider(this._native) {
    _init();
  }

  List<Map<String, dynamic>> get apps => _apps;
  bool get loading => _loading;

  Future<void> _init() async {
    // initial load
    await refreshApps();
    // listen to package events
    _native.packageEvents.listen((ev) async {
      final event = ev['event'] ?? '';
      final pkg = ev['packageName'] ?? '';
      await refreshApps();
      if (event == 'removed') {
        // remove from favorites
        try {
          final favs = HiveService.getFavorites();
          if (favs.contains(pkg)) {
            favs.remove(pkg);
            await HiveService.setFavorites(favs);
          }
        } catch (_) {}
        // remove from blocked apps
        try {
          final blocked = HiveService.getBlockedApps();
          if (blocked.contains(pkg)) {
            blocked.remove(pkg);
            await HiveService.setBlockedApps(blocked);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> refreshApps() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _native.getInstalledApps();
      _apps = list;
    } catch (e) {
      _apps = [];
    }
    _loading = false;
    notifyListeners();
  }
}
