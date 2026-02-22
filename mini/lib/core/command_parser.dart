import 'package:flutter/material.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'package:auraless/providers/terminal_history_provider.dart';
import 'package:auraless/core/hive_service.dart';
import 'package:auraless/screens/settings_screen.dart';
import 'package:auraless/screens/setup_wizard.dart';
import 'package:auraless/features/digital_wellbeing/providers/blocked_apps_provider.dart';
// ...existing code...
import 'package:auraless/screens/usage_stats_screen.dart';
import 'package:auraless/providers/usage_stats_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CommandParser {
  final BuildContext context;
  final NativeChannelService native;
  final TerminalHistoryProvider historyProvider;

  // aliases are persisted in Hive; don't keep a separate in-memory source of truth

  CommandParser({
    required this.context,
    required this.native,
    required this.historyProvider,
  });

  Future<void> execute(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    // apply alias substitution
    final parts = trimmed.split(RegExp(r"\s+"));
    final cmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    try {
      switch (cmd) {
        case 'help':
          _cmdHelp();
          break;
        case 'open':
          await _cmdOpen(args);
          break;
        case 'call':
          await _cmdCall(args);
          break;
        case 'search':
          await _cmdSearch(args);
          break;
        case 'ls':
          await _cmdListApps();
          break;

        case 'stats':
          await _cmdStats(args);
          break;
        case 'usage':
          _cmdUsage();
          break;
        case 'status':
          await _cmdStatus();
          break;
        case 'lock':
          await _cmdLock(args);
          break;
        case 'unlock':
          await _cmdUnlock(args);
          break;
        case 'focus':
          await _cmdFocus(args);
          break;
        case 'grayscale':
          await _cmdGrayscale(args);
          break;
        case 'alias':
          await _cmdAlias(args);
          break;
        case 'notifications':
          await _cmdNotifications(args);
          break;
        case 'essential':
          await _cmdEssential(args);
          break;
        case 'settings':
          _cmdSettings();
          break;
        case 'battery':
          await _cmdBattery(args);
          break;
        case 'about':
          await _cmdAbout();
          break;
        case 'battery_optimization':
          await _cmdBattery(args);
          break;
        case 'setup':
          _cmdSetup();
          break;
        case 'clear':
          historyProvider.clear();
          break;
        default:
          historyProvider.addError(
            'Unknown command: $cmd. Usage: help. Example: help',
          );
      }
    } catch (e) {
      historyProvider.addError('Error: ${e.toString()}');
    }
  }

  void _cmdHelp() {
    final lines = <String>[
      'help - list commands',
      'open <app name or package> - launch app',
      'call <contact> - call a contact by name',
      'search <query> - open a web search for the query',
      'ls - list installed apps',
      // removed 'top' command (use 'stats' instead)
      'stats - usage stats (placeholder)',
      'status - show system info',
      'lock <app> [minutes] - block app (minutes optional, not enforced in MVP)',
      'unlock - placeholder',
      'focus - placeholder',
      'grayscale - placeholder',
      'alias - manage aliases',
      'settings - open settings',
      'battery - check battery optimization state (use "battery open" to open settings)',
      'about - show app information (version, repo, contributors)',
      'battery_optimization - alias for battery',
      'clear - clear terminal',
    ];
    for (var l in lines) {
      historyProvider.addOutput(l);
    }
  }

  Future<void> _cmdOpen(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError(
        'Missing app name. Usage: open <app name or package>. Example: open instagram',
      );
      return;
    }
    // join args into a single query and expand aliases from Hive
    var query = args.join(' ').trim();
    try {
      final aliases = HiveService.getAliases();
      if (aliases.containsKey(query)) {
        final val = aliases[query]!.trim();
        // if alias stores a full command like "open com.example.app", extract the target
        if (val.toLowerCase().startsWith('open ')) {
          query = val.substring(5).trim();
        } else {
          query = val;
        }
      }
    } catch (_) {
      // ignore hive read errors and continue with original query
    }
    // fetch installed apps
    final apps = await native.getInstalledApps();
    // matching strategy: prefer exact matches, then prefix matches, then substring matches
    final lower = query.toLowerCase();
    Map<String, dynamic> match = {};

    // helper to normalize fields
    String nameOf(Map a) => (a['name'] ?? '').toString().toLowerCase();
    String pkgOf(Map a) => (a['packageName'] ?? '').toString().toLowerCase();

    // 1) exact name or exact package
    for (var a in apps) {
      if (nameOf(a) == lower || pkgOf(a) == lower) {
        match = Map<String, dynamic>.from(a);
        break;
      }
    }

    // 2) exact package (with possible user passing full package)
    if (match.isEmpty) {
      for (var a in apps) {
        if (pkgOf(a) == lower) {
          match = Map<String, dynamic>.from(a);
          break;
        }
      }
    }

    // 3) prefix matches on name or package
    if (match.isEmpty) {
      for (var a in apps) {
        if (nameOf(a).startsWith(lower) || pkgOf(a).startsWith(lower)) {
          match = Map<String, dynamic>.from(a);
          break;
        }
      }
    }

    // 4) whole-word match in name (e.g., 'mess' should match 'Messages')
    if (match.isEmpty) {
      for (var a in apps) {
        final words = nameOf(a).split(RegExp(r"\s+|[._-]"));
        if (words.contains(lower)) {
          match = Map<String, dynamic>.from(a);
          break;
        }
      }
    }

    // 5) fallback: substring match
    if (match.isEmpty) {
      for (var a in apps) {
        if (nameOf(a).contains(lower) || pkgOf(a).contains(lower)) {
          match = Map<String, dynamic>.from(a);
          break;
        }
      }
    }
    if (match.isEmpty) {
      historyProvider.addError(
        'No app matching "$query". Usage: open <app name or package>. Example: open instagram',
      );
      return;
    }
    final pkgName = match['packageName'] as String?;
    if (pkgName == null) {
      historyProvider.addError(
        'Unable to determine package name for matched app. Usage: open <app name or package>. Example: open instagram',
      );
      return;
    }
    final ok = await native.launchApp(pkgName);
    if (ok) {
      historyProvider.addOutput('Launched ${match['name']}');
    } else {
      historyProvider.addError(
        'Failed to launch ${match['name']}. Usage: open <app name or package>. Example: open instagram',
      );
    }
  }

  Future<void> _cmdCall(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError(
        'Missing contact name. Usage: call <name>. Example: call Alice',
      );
      return;
    }
    final query = args.join(' ').trim();

    // ensure permission
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      final req = await Permission.contacts.request();
      if (!req.isGranted) {
        historyProvider.addError(
          'Contacts permission denied. Cannot perform call.',
        );
        return;
      }
    }

    try {
      final results = await native.searchContacts(query);
      if (results.isEmpty) {
        historyProvider.addError('No contact found matching "$query"');
        return;
      }
      final first = results.first;
      final number = first['number']?.toString() ?? '';
      final name = first['name'] ?? number;
      if (number.isEmpty) {
        historyProvider.addError(
          'Contact found but no phone number available for $name',
        );
        return;
      }
      final ok = await native.openDialer(number);
      if (ok) {
        historyProvider.addOutput('Opened dialer for $name ($number)');
      } else {
        historyProvider.addError('Failed to open dialer for $number');
      }
    } catch (e) {
      historyProvider.addError('Failed to search contacts: ${e.toString()}');
    }
  }

  Future<void> _cmdSearch(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError(
        'Missing query. Usage: search <query>. Example: search photos',
      );
      return;
    }
    final query = args.join(' ');
    final encoded = Uri.encodeQueryComponent(query);
    final url = 'https://www.google.com/search?q=$encoded';
    try {
      final ok = await native.openUrl(url);
      if (ok) {
        historyProvider.addOutput('Opened search for: $query');
      } else {
        historyProvider.addError('Failed to open browser for search');
      }
    } catch (e) {
      historyProvider.addError('Search failed: ${e.toString()}');
    }
  }

  // ... no-op placeholder removed; commands now have concrete implementations

  Future<void> _cmdListApps() async {
    final apps = await native.getInstalledApps();
    if (apps.isEmpty) {
      historyProvider.addOutput('No apps found');
      return;
    }
    for (var a in apps) {
      historyProvider.addOutput(a['name'] ?? a['packageName'] ?? 'unknown');
    }
  }

  Future<void> _cmdStatus() async {
    final info = await native.getSystemInfo();
    historyProvider.addOutput('Model: ${info['model'] ?? '-'}');
    historyProvider.addOutput(
      'Android: ${info['androidVersion']} (API ${info['apiLevel']})',
    );
    historyProvider.addOutput('Kernel: ${info['kernelVersion'] ?? '-'}');
    historyProvider.addOutput('Uptime (min): ${info['uptimeMinutes'] ?? '-'}');
    historyProvider.addOutput('Battery %: ${info['batteryPercent'] ?? '-'}');
    historyProvider.addOutput(
      'RAM used/total: ${info['ramUsed'] ?? '-'} / ${info['ramTotal'] ?? '-'}',
    );
    historyProvider.addOutput(
      'Storage used/total: ${info['storageUsed'] ?? '-'} / ${info['storageTotal'] ?? '-'}',
    );
    historyProvider.addOutput('Network: ${info['networkType'] ?? '-'}');
  }

  // ...previous placeholder removed; see async _cmdLock implementation below

  Future<void> _cmdAlias(List<String> args) async {
    if (args.isEmpty) {
      // list
      final aliases = HiveService.getAliases();
      if (aliases.isEmpty) {
        historyProvider.addOutput('No aliases defined');
      } else {
        aliases.forEach((k, v) => historyProvider.addOutput('$k => $v'));
      }
      return;
    }
    final sub = args[0];
    if (sub == 'add' && args.length >= 3) {
      final name = args[1];
      final command = args.sublist(2).join(' ');
      await HiveService.putAlias(name, command);
      historyProvider.addOutput('Alias added: $name => $command');
      return;
    }
    if (sub == 'remove' && args.length >= 2) {
      final name = args[1];
      await HiveService.removeAlias(name);
      historyProvider.addOutput('Alias removed: $name');
      return;
    }
    historyProvider.addError(
      'Invalid alias command. Usage: alias [add|remove] <name> <command>. Example: alias add g "open com.example.app"',
    );
  }

  void _cmdSettings() {
    // navigate to settings screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    historyProvider.addOutput('Opened settings (placeholder)');
  }

  void _cmdSetup() {
    // Re-run the setup wizard
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SetupWizard()));
    historyProvider.addOutput('Reopened setup wizard');
  }

  void _cmdUsage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UsageStatsScreen()));
    historyProvider.addOutput('Opened usage stats');
  }

  Future<void> _cmdLock(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError(
        'Invalid usage. Usage: lock <app> [minutes]. Example: lock instagram 30',
      );
      return;
    }
    final query = args[0];
    int? minutes;
    if (args.length >= 2) {
      minutes = int.tryParse(args[1]);
    }
    // find app
    final apps = await native.getInstalledApps();
    final lower = query.toLowerCase();
    final match = apps.firstWhere((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final pkg = (a['packageName'] ?? '').toString().toLowerCase();
      return name.contains(lower) || pkg.contains(lower);
    }, orElse: () => {});
    if (match.isEmpty) {
      historyProvider.addError(
        'No app matching "$query". Usage: lock <app> [minutes]. Example: lock instagram 30',
      );
      return;
    }
    final pkgName = match['packageName'] as String?;
    if (pkgName == null) {
      historyProvider.addError(
        'Unable to determine package name for matched app. Usage: lock <app> [minutes]. Example: lock instagram 30',
      );
      return;
    }

    // Check accessibility service status
    final accessEnabled = await native
        .isAccessibilityServiceEnabled()
        .catchError((_) => false);
    if (!accessEnabled) {
      historyProvider.addOutput(
        'Accessibility service is not enabled. Opening settings...',
      );
      await native.openAccessibilitySettings();
      return;
    }

    try {
      await native.addBlockedApp(pkgName);
      if (minutes != null) {
        historyProvider.addOutput(
          'Blocked ${match['name']} ($pkgName) for $minutes minutes (note: automatic unblock not implemented)',
        );
      } else {
        historyProvider.addOutput('Blocked ${match['name']} ($pkgName)');
      }
    } catch (e) {
      historyProvider.addError(
        'Failed to block $pkgName: ${e.toString()}. Usage: lock <app> [minutes]. Example: lock instagram 30',
      );
    }
  }

  Future<void> _cmdAbout() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final appName = info.appName;
      final version =
          info.version +
          (info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : '');

      // Build date can be hardcoded or injected via build; using a conservative hardcoded value placeholder.
      const buildDate = '2026-02-21';
      const repo = 'https://github.com/PersuasivePost/minimalistic-mobile';
      const contributors = 'PersuasivePost';

      historyProvider.addOutput('');
      historyProvider.addOutput('=== About ===');
      historyProvider.addOutput('App: $appName');
      historyProvider.addOutput('Version: $version');
      historyProvider.addOutput('Build date: $buildDate');
      historyProvider.addOutput('Repository: $repo');
      historyProvider.addOutput('Contributors: $contributors');
      historyProvider.addOutput('============');
    } catch (e) {
      historyProvider.addError(
        'Failed to read package info: ${e.toString()}. Usage: about. Example: about',
      );
    }
  }

  Future<void> _cmdUnlock(List<String> args) async {
    // if no args, list blocked
    if (args.isEmpty) {
      try {
        final list = await native.getBlockedApps();
        if (list.isEmpty) {
          historyProvider.addOutput('No blocked apps');
        } else {
          for (var p in list) {
            historyProvider.addOutput(p);
          }
        }
      } catch (e) {
        historyProvider.addError(
          'Failed to fetch blocked apps: ${e.toString()}. Usage: unlock [app]. Example: unlock instagram',
        );
      }
      return;
    }

    final query = args[0];
    // try resolve package by name
    final apps = await native.getInstalledApps();
    final lower = query.toLowerCase();
    final match = apps.firstWhere((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final pkg = (a['packageName'] ?? '').toString().toLowerCase();
      return name.contains(lower) || pkg.contains(lower) || pkg == lower;
    }, orElse: () => {});
    String? pkgName;
    if (match.isEmpty) {
      // maybe the user passed the package directly
      pkgName = query;
    } else {
      pkgName = match['packageName'] as String?;
    }

    if (pkgName == null) {
      historyProvider.addError(
        'Unable to determine package name for matched app. Usage: unlock <app|package>. Example: unlock com.instagram.android',
      );
      return;
    }

    try {
      await native.removeBlockedApp(pkgName);
      historyProvider.addOutput('Unblocked $pkgName');
    } catch (e) {
      historyProvider.addError(
        'Failed to unblock $pkgName: ${e.toString()}. Usage: unlock <app|package>. Example: unlock instagram',
      );
    }
  }

  Future<void> _cmdGrayscale(List<String> args) async {
    // support: grayscale on | grayscale off
    if (args.isEmpty) {
      historyProvider.addOutput('Usage: grayscale on|off');
      return;
    }
    final mode = args[0].toLowerCase();
    try {
      if (mode == 'on' || mode == 'true' || mode == '1') {
        final ok = await native.enableGrayscale();
        if (ok) {
          historyProvider.addOutput('Grayscale enabled');
        } else {
          historyProvider.addOutput(
            'Permission denied. Run: adb shell pm grant <your.app.package> android.permission.WRITE_SECURE_SETTINGS',
          );
        }
        return;
      }
      if (mode == 'off' || mode == 'false' || mode == '0') {
        final ok = await native.disableGrayscale();
        if (ok) {
          historyProvider.addOutput('Grayscale disabled');
        } else {
          historyProvider.addOutput(
            'Permission denied. Run: adb shell pm grant <your.app.package> android.permission.WRITE_SECURE_SETTINGS',
          );
        }
        return;
      }
      historyProvider.addError(
        'Unknown mode: $mode. Usage: grayscale on|off. Example: grayscale on',
      );
    } catch (e) {
      historyProvider.addError(
        'Error toggling grayscale: ${e.toString()}. Usage: grayscale on|off. Example: grayscale on',
      );
    }
  }

  Future<void> _cmdNotifications(List<String> args) async {
    // show last 20 notifications
    try {
      final list = await native.getNotificationDigest();
      if (list.isEmpty) {
        historyProvider.addOutput('No notifications');
        return;
      }
      final total = list.length;
      final start = total > 20 ? total - 20 : 0;
      final take = list.sublist(start, total).reversed.toList();
      int idx = 0;
      for (var n in take) {
        idx++;
        final pkg = n['package'] ?? '';
        final title = n['title'] ?? '';
        final text = n['text'] ?? '';
        historyProvider.addOutput('$idx. [$pkg] $title - $text');
      }
    } catch (e) {
      historyProvider.addError(
        'Failed to fetch notifications: ${e.toString()}. Usage: notifications. Example: notifications',
      );
    }
  }

  Future<void> _cmdEssential(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError(
        'Invalid usage. Usage: essential [add|remove|list] <app>. Example: essential add com.example.app',
      );
      return;
    }
    final sub = args[0];
    if (sub == 'list') {
      try {
        final list = await native.getEssentialPackages();
        if (list.isEmpty) {
          historyProvider.addOutput('No essential packages');
        } else {
          for (var p in list) {
            historyProvider.addOutput(p);
          }
        }
      } catch (e) {
        historyProvider.addError(
          'Failed to fetch essentials: ${e.toString()}. Usage: essential list. Example: essential list',
        );
      }
      return;
    }
    if (args.length < 2) {
      historyProvider.addError(
        'Invalid usage. Usage: essential [add|remove|list] <app>. Example: essential add instagram',
      );
      return;
    }
    final app = args.sublist(1).join(' ');
    // try to resolve package name
    final apps = await native.getInstalledApps();
    final lower = app.toLowerCase();
    final match = apps.firstWhere((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final pkg = (a['packageName'] ?? '').toString().toLowerCase();
      return name.contains(lower) || pkg.contains(lower);
    }, orElse: () => {});
    String pkgName = match.isEmpty
        ? app
        : (match['packageName'] as String? ?? app);

    try {
      if (sub == 'add') {
        await native.addEssentialPackage(pkgName);
        historyProvider.addOutput('Added essential $pkgName');
      } else if (sub == 'remove') {
        await native.removeEssentialPackage(pkgName);
        historyProvider.addOutput('Removed essential $pkgName');
      } else {
        historyProvider.addError(
          'Unknown subcommand: $sub. Usage: essential [add|remove|list] <app>. Example: essential add instagram',
        );
      }
    } catch (e) {
      historyProvider.addError(
        'Failed to modify essential packages: ${e.toString()}',
      );
    }
  }

  Future<void> _cmdFocus(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addOutput('Usage: focus on|off');
      return;
    }
    final mode = args[0].toLowerCase();
    // create provider instance to perform blocking operations
    final bap = BlockedAppsProvider(native);
    if (mode == 'on') {
      await bap.enableFocusMode();
      historyProvider.addOutput(
        'Focus mode activated. Non-essential apps blocked.',
      );
      return;
    }
    if (mode == 'off') {
      await bap.disableFocusMode();
      historyProvider.addOutput(
        'Focus mode disabled. Restored previous blocked apps.',
      );
      return;
    }
    historyProvider.addError(
      'Unknown mode: $mode. Usage: focus on|off. Example: focus on',
    );
  }

  Future<void> _cmdStats(List<String> args) async {
    DateTime day = DateTime.now();
    if (args.isNotEmpty) {
      final a = args[0].toLowerCase();
      if (a == 'today') {
        day = DateTime.now();
      } else if (a == 'yesterday') {
        day = DateTime.now().subtract(const Duration(days: 1));
      } else {
        // try parse yyyy-mm-dd
        try {
          day = DateTime.parse(a);
        } catch (e) {
          historyProvider.addError(
            'Invalid date: $a. Usage: stats [today|yesterday|yyyy-mm-dd]. Example: stats 2026-02-20',
          );
          return;
        }
      }
    }

    final provider = UsageStatsProvider(native);
    await provider.loadForDay(day);
    if (provider.entries.isEmpty) {
      // check permission
      final has = await native.hasUsageStatsPermission().catchError(
        (_) => false,
      );
      if (!has) {
        historyProvider.addOutput(
          'Usage permission not granted. Run the usage permission settings.',
        );
        await native.requestUsageStatsPermission();
        return;
      }
      historyProvider.addOutput(
        'No usage data for ${day.toIso8601String().split('T').first}',
      );
      return;
    }

    // Show top 5 + aggregated Other
    final list = provider.topWithOther(n: 5);
    final apps = await native.getInstalledApps();
    int idx = 0;
    for (final e in list) {
      if (e.packageName == 'Other') {
        final mins = (e.totalTimeInForeground / 60000).round();
        final label = mins >= 60
            ? '${(mins / 60).toStringAsFixed(1)}h'
            : '${mins}m';
        historyProvider.addOutput('Other – $label');
        continue;
      }
      idx++;
      final mins = (e.totalTimeInForeground / 60000).round();
      final label = mins >= 60
          ? '${(mins / 60).toStringAsFixed(1)}h'
          : '${mins}m';
      final found = apps.firstWhere(
        (a) => (a['packageName'] ?? '') == e.packageName,
        orElse: () => {},
      );
      final name = found.isEmpty
          ? e.packageName
          : (found['name'] ?? e.packageName);
      historyProvider.addOutput('$idx. $name – $label');
    }
  }

  Future<void> _cmdBattery(List<String> args) async {
    try {
      final ignoring = await native.isIgnoringBatteryOptimizations().catchError(
        (_) => true,
      );
      if (ignoring) {
        historyProvider.addOutput(
          'Device is ignoring battery optimizations for this app (ok)',
        );
        return;
      }
      historyProvider.addOutput(
        'Battery optimizations may affect background behavior.',
      );
      // if args contains 'open' or user confirms, open settings
      if (args.isNotEmpty && (args[0] == 'open' || args[0] == 'settings')) {
        await native.openBatteryOptimizationSettings();
        historyProvider.addOutput('Opened battery optimization settings');
        return;
      }
      historyProvider.addOutput(
        'Run: battery open   to open battery optimization settings',
      );
    } catch (e) {
      historyProvider.addError(
        'Battery check failed: ${e.toString()}. Usage: battery. Example: battery open',
      );
    }
  }
}
