import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class SystemInfoProvider extends ChangeNotifier {
  final NativeChannelService _native;
  Map<String, dynamic>? _info;
  bool _loading = false;
  Timer? _timer;

  // refresh interval in minutes
  static const int refreshMinutes = 5;

  SystemInfoProvider(this._native);

  Map<String, dynamic>? get info => _info;
  bool get isLoading => _loading;

  Future<void> refreshInfo() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _native.getSystemInfo();
      _info = result;
    } catch (_) {
      // keep existing info on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void startPeriodic() {
    if (_timer != null) return;
    // initial refresh
    refreshInfo();
    _timer = Timer.periodic(const Duration(minutes: refreshMinutes), (_) {
      refreshInfo();
    });
  }

  void stopPeriodic() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
