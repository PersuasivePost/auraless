import 'package:flutter/widgets.dart';

class LifecycleProvider extends ChangeNotifier {
  AppLifecycleState? _state;
  DateTime? _lastResume;

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
    notifyListeners();
  }
}
