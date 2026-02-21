import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class UsageEntry {
  final String packageName;
  final int totalTimeInForeground;

  UsageEntry({required this.packageName, required this.totalTimeInForeground});
}

class UsageStatsProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<UsageEntry> _entries = [];
  bool _loading = false;

  UsageStatsProvider(this._native);

  List<UsageEntry> get entries => _entries;
  bool get loading => _loading;

  Future<void> loadForDay(DateTime day) async {
    _loading = true;
    notifyListeners();

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    try {
      final hasPerm = await _native.hasUsageStatsPermission();
      if (!hasPerm) {
        // Do not throw; just empty list
        _entries = [];
      } else {
        final raw = await _native.getUsageStats(start, end);
        _entries =
            raw.map((m) {
              return UsageEntry(
                packageName: m['packageName']?.toString() ?? '',
                totalTimeInForeground: (m['totalTimeInForeground'] is int)
                    ? m['totalTimeInForeground'] as int
                    : (m['totalTimeInForeground'] as num).toInt(),
              );
            }).toList()..sort(
              (a, b) =>
                  b.totalTimeInForeground.compareTo(a.totalTimeInForeground),
            );
      }
    } catch (e) {
      _entries = [];
    }

    _loading = false;
    notifyListeners();
  }
}
