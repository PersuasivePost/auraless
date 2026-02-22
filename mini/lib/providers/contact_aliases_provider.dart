import 'package:flutter/material.dart';
import 'package:auraless/core/hive_service.dart';

class ContactAliasesProvider extends ChangeNotifier {
  Map<String, String> _map = {};

  ContactAliasesProvider() {
    _map = HiveService.getContactAliases();
  }

  Map<String, String> get map => Map.unmodifiable(_map);

  Future<void> refresh() async {
    _map = HiveService.getContactAliases();
    notifyListeners();
  }

  Future<void> put(String name, String phone) async {
    await HiveService.putContactAlias(name, phone);
    _map[name] = phone;
    notifyListeners();
  }

  Future<void> remove(String name) async {
    await HiveService.removeContactAlias(name);
    _map.remove(name);
    notifyListeners();
  }
}
