import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'package:auraless/core/hive_service.dart';

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

  /// Enable focus mode: block all non-essential apps and save previous blocked list
  Future<void> enableFocusMode() async {
    _loading = true;
    notifyListeners();
    try {
      final installed = await _native.getInstalledApps();
      final essential = await _native.getEssentialPackages();
      final prev = await _native.getBlockedApps();

      // compute apps to block: installed packages not in essential and not already blocked
      final toBlock = <String>[];
      for (var a in installed) {
        final pkg = (a['packageName'] ?? '').toString();
        if (pkg.isEmpty) continue;
        if (essential.contains(pkg)) continue;
        if (prev.contains(pkg)) continue;
        // also skip our own package
        if (pkg == (await _native.getSystemInfo())['packageName']) continue;
        toBlock.add(pkg);
      }

      // store previous blocked list in Hive so we can restore later
      await HiveService.setSetting('focus_prev_blocked', prev);

      // add blocks
      for (var p in toBlock) {
        await _native.addBlockedApp(p);
      }
      await refresh();
    } catch (e) {
      // ignore
    }
    _loading = false;
    notifyListeners();
  }

  /// Disable focus mode by restoring the previous blocked list saved when enabling focus
  Future<void> disableFocusMode() async {
    _loading = true;
    notifyListeners();
    try {
      final prev =
          (HiveService.getSetting(
                    'focus_prev_blocked',
                    defaultValue: <String>[],
                  )
                  as List)
              .cast<String>();
      final current = await _native.getBlockedApps();

      // remove any currently blocked app that was not in prev
      for (var p in current) {
        if (!prev.contains(p)) {
          await _native.removeBlockedApp(p);
        }
      }

      // ensure previous ones are present
      for (var p in prev) {
        if (!((await _native.getBlockedApps()).contains(p))) {
          await _native.addBlockedApp(p);
        }
      }

      // clear stored previous
      await HiveService.setSetting('focus_prev_blocked', <String>[]);

      await refresh();
    } catch (e) {
      // ignore
    }
    _loading = false;
    notifyListeners();
  }
}
