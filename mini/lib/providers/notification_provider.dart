import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class NotificationEntry {
  final String packageName;
  final String title;
  final String text;
  final int postTime;

  NotificationEntry({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });
}

class NotificationProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<NotificationEntry> _entries = [];
  bool _loading = false;

  NotificationProvider(this._native);

  List<NotificationEntry> get entries => _entries;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await _native.getNotificationDigest();
      _entries = raw
          .map((m) {
            return NotificationEntry(
              packageName: m['package'] ?? '',
              title: m['title'] ?? '',
              text: m['text'] ?? '',
              postTime: (m['postTime'] is int)
                  ? m['postTime'] as int
                  : (m['postTime'] as num).toInt(),
            );
          })
          .toList()
          .reversed
          .toList(); // show newest first
    } catch (e) {
      _entries = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    await _native.clearNotificationDigest();
    await refresh();
  }

  Future<void> addEssential(String pkg) async {
    await _native.addEssentialPackage(pkg);
  }

  Future<void> removeEssential(String pkg) async {
    await _native.removeEssentialPackage(pkg);
  }

  Future<List<String>> getEssentials() async {
    return await _native.getEssentialPackages();
  }
}
