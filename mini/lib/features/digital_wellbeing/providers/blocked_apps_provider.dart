import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class BlockedAppsProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<String> _blocked = [];
  bool _loading = false;

  BlockedAppsProvider(this._native);

  List<String> get blocked => _blocked;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _blocked = await _native.getBlockedApps();
    } catch (e) {
      _blocked = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add(String packageName) async {
    await _native.addBlockedApp(packageName);
    await refresh();
  }

  Future<void> remove(String packageName) async {
    await _native.removeBlockedApp(packageName);
    await refresh();
  }
}
