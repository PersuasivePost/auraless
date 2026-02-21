import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mini/core/native_channel_service.dart';
import 'package:mini/providers/terminal_history_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// small struct for tracked permissions
class _PermissionState {
  bool usage;
  bool accessibility;
  bool notification;
  bool contacts;
  _PermissionState({
    bool usage = false,
    bool accessibility = false,
    bool notification = false,
    bool contacts = false,
  }) : usage = usage,
       accessibility = accessibility,
       notification = notification,
       contacts = contacts;
}

class LifecycleProvider extends ChangeNotifier {
  AppLifecycleState? _state;
  DateTime? _lastResume;
  final NativeChannelService _native = NativeChannelService();
  Timer? _timer;
  _PermissionState _permState = _PermissionState();

  void startPeriodicChecks(TerminalHistoryProvider history) {
    // run immediately and then every 30s
    _checkPermissions(history);
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkPermissions(history),
    );
  }

  void stopPeriodicChecks() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkPermissions(TerminalHistoryProvider history) async {
    try {
      final usage = await _native.hasUsageStatsPermission().catchError(
        (_) => false,
      );
      final acc = await _native.isAccessibilityServiceEnabled().catchError(
        (_) => false,
      );
      final notif = await _native.isNotificationListenerEnabled().catchError(
        (_) => false,
      );
      final cont = await Permission.contacts.status
          .then((s) => s.isGranted)
          .catchError((_) => false);

      if (_permState.usage && !usage) {
        history.addError(
          'Warning: Usage stats permission revoked. Some features disabled.',
        );
      }
      if (_permState.accessibility && !acc) {
        history.addError(
          'Warning: Accessibility service disabled. App blocking will not work.',
        );
      }
      if (_permState.notification && !notif) {
        history.addError(
          'Warning: Notification access revoked. Notification digest will not be available.',
        );
      }
      if (_permState.contacts && !cont) {
        history.addError(
          'Warning: Contacts permission revoked. Contact-dependent features disabled.',
        );
      }

      _permState.usage = usage;
      _permState.accessibility = acc;
      _permState.notification = notif;
      _permState.contacts = cont;
    } catch (_) {}
  }

  AppLifecycleState? get currentState => _state;
  DateTime? get lastResume => _lastResume;

  void setState(AppLifecycleState state) {
    _state = state;
    notifyListeners();
  }

  /// Call when the app resumes. Updates internal state and notifies listeners.
  void onResume() {
    _state = AppLifecycleState.resumed;
    _lastResume = DateTime.now();
    try {
      // notify listeners first
      notifyListeners();
      // Attempt to get the terminal history provider from current context via a callback in main app
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
