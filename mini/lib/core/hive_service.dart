import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static late Box settingsBox;
  static late Box favoritesBox;
  static late Box blockedAppsBox;
  static late Box aliasesBox;
  static late Box userCommandsBox;
  static late Box terminalHistoryBox;
  static late Box notificationsBox;

  /// Initialize Hive and open required boxes.
  static Future<void> init() async {
    await Hive.initFlutter();

    // using simple Box names and primitive types for now
    settingsBox = await Hive.openBox('settings');
    favoritesBox = await Hive.openBox('favorites');
    blockedAppsBox = await Hive.openBox('blockedApps');
    aliasesBox = await Hive.openBox('aliases');
    userCommandsBox = await Hive.openBox('userCommands');
    terminalHistoryBox = await Hive.openBox('terminalHistory');
    notificationsBox = await Hive.openBox('notifications');
  }

  // Settings helpers
  static dynamic getSetting(String key, {dynamic defaultValue}) =>
      settingsBox.get(key, defaultValue: defaultValue);
  static Future<void> setSetting(String key, dynamic value) async =>
      settingsBox.put(key, value);

  // Favorites helpers
  static List<String> getFavorites() =>
      favoritesBox.get('list', defaultValue: <String>[])?.cast<String>() ??
      <String>[];
  static Future<void> setFavorites(List<String> list) async =>
      favoritesBox.put('list', list);
  static Future<void> addFavorite(String pkg) async {
    final list = getFavorites();
    if (!list.contains(pkg)) {
      list.add(pkg);
      await setFavorites(list);
    }
  }

  static Future<void> removeFavorite(String pkg) async {
    final list = getFavorites();
    list.remove(pkg);
    await setFavorites(list);
  }

  // Blocked apps helpers
  static List<String> getBlockedApps() =>
      blockedAppsBox.get('list', defaultValue: <String>[])?.cast<String>() ??
      <String>[];
  static Future<void> setBlockedApps(List<String> list) async =>
      blockedAppsBox.put('list', list);

  // Aliases
  static Map<String, String> getAliases() {
    final raw =
        aliasesBox.get('map', defaultValue: <String, dynamic>{}) as Map?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  static Future<void> setAliases(Map<String, String> map) async =>
      aliasesBox.put('map', map);
  static Future<void> putAlias(String key, String command) async {
    final map = getAliases();
    map[key] = command;
    await setAliases(map);
  }

  static Future<void> removeAlias(String key) async {
    final map = getAliases();
    map.remove(key);
    await setAliases(map);
  }

  // User commands
  static Map<String, String> getUserCommands() {
    final raw =
        userCommandsBox.get('map', defaultValue: <String, dynamic>{}) as Map?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  static Future<void> setUserCommands(Map<String, String> map) async =>
      userCommandsBox.put('map', map);

  // Terminal history
  static List<String> getTerminalHistory() =>
      terminalHistoryBox
          .get('list', defaultValue: <String>[])
          ?.cast<String>() ??
      <String>[];
  static Future<void> pushTerminalHistory(String entry) async {
    final list = getTerminalHistory();
    list.add(entry);
    await terminalHistoryBox.put('list', list);
  }

  static Future<void> clearTerminalHistory() async =>
      terminalHistoryBox.put('list', <String>[]);

  // Notifications
  static List<dynamic> getNotifications() =>
      notificationsBox.get('list', defaultValue: <dynamic>[]) as List<dynamic>;
  static Future<void> setNotifications(List<dynamic> list) async =>
      notificationsBox.put('list', list);
}
