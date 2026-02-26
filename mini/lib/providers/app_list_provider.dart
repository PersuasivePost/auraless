import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class AppListProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<Map<String, dynamic>> _apps = [];
  bool _loading = false;
  StreamSubscription<Map<String, String>>? _pkgSub;

  AppListProvider(this._native) {
    _init();
  }

  List<Map<String, dynamic>> get apps => List.unmodifiable(_apps);
  bool get isLoading => _loading;

  Future<void> _init() async {
    _pkgSub = _native.packageEvents.listen((event) {
      // refresh in background on installs/uninstalls
      refreshAppList();
    });
    await refreshAppList();
  }

  Future<void> refreshAppList() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final fetched = await _native.getInstalledApps();
      _apps = fetched;
    } catch (_) {
      // ignore errors; keep existing cache
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pkgSub?.cancel();
    super.dispose();
  }
}
