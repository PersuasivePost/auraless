import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:auraless/core/native_channel_service.dart';

class ContactsProvider extends ChangeNotifier {
  final NativeChannelService _native;
  List<Map<String, String>> _contacts = [];
  bool _loading = false;
  Timer? _periodic;

  ContactsProvider(this._native) {
    _init();
  }

  List<Map<String, String>> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _loading;

  Future<void> _init() async {
    await refreshContacts();
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshContacts();
    });
  }

  Future<void> refreshContacts() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final fetched = await _native.searchContacts('');
      _contacts = fetched
          .map(
            (m) => Map<String, String>.from(
              m.map((k, v) => MapEntry(k.toString(), v.toString())),
            ),
          )
          .toList();
    } catch (_) {
      // keep existing cache on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _periodic?.cancel();
    super.dispose();
  }
}
