import 'package:flutter/material.dart';
import 'package:mini/core/native_channel_service.dart';
import 'package:mini/providers/terminal_history_provider.dart';
import 'package:mini/screens/settings_screen.dart';
// ...existing code...
import 'package:mini/screens/usage_stats_screen.dart';
import 'package:mini/providers/usage_stats_provider.dart';

class CommandParser {
  final BuildContext context;
  final NativeChannelService native;
  final TerminalHistoryProvider historyProvider;

  final Map<String, String> _aliases = {};

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
          _cmdPlaceholder('call', args.join(' '));
          break;
        case 'search':
          _cmdPlaceholder('search', args.join(' '));
          break;
        case 'ls':
          await _cmdListApps();
          break;
        case 'top':
          _cmdPlaceholder('top', 'Top used apps (placeholder)');
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
          _cmdAlias(args);
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
        case 'clear':
          historyProvider.clear();
          break;
        default:
          historyProvider.addError('Unknown command: $cmd');
      }
    } catch (e) {
      historyProvider.addError('Error: ${e.toString()}');
    }
  }

  void _cmdHelp() {
    final lines = <String>[
      'help - list commands',
      'open <app name or package> - launch app',
      'call <contact> - placeholder',
      'search <query> - placeholder',
      'ls - list installed apps',
      'top - top used apps (placeholder)',
      'stats - usage stats (placeholder)',
      'status - show system info',
      'lock <app> [minutes] - block app (minutes optional, not enforced in MVP)',
      'unlock - placeholder',
      'focus - placeholder',
      'grayscale - placeholder',
      'alias - manage aliases',
      'settings - open settings',
      'clear - clear terminal',
    ];
    for (var l in lines) {
      historyProvider.addOutput(l);
    }
  }

  Future<void> _cmdOpen(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError('Usage: open <app name or package>');
      return;
    }
    final query = args.join(' ');
    // fetch installed apps
    final apps = await native.getInstalledApps();
    // fuzzy match: name or package contains query
    final lower = query.toLowerCase();
    final match = apps.firstWhere((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final pkg = (a['packageName'] ?? '').toString().toLowerCase();
      return name.contains(lower) || pkg.contains(lower);
    }, orElse: () => {});
    if (match.isEmpty) {
      historyProvider.addError('No app matching "$query"');
      return;
    }
    final pkgName = match['packageName'] as String?;
    if (pkgName == null) {
      historyProvider.addError('No packageName for matched app');
      return;
    }
    final ok = await native.launchApp(pkgName);
    if (ok) {
      historyProvider.addOutput('Launched ${match['name']}');
    } else {
      historyProvider.addError('Failed to launch ${match['name']}');
    }
  }

  void _cmdPlaceholder(String name, String message) {
    historyProvider.addOutput('$name: $message');
  }

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

  void _cmdAlias(List<String> args) {
    if (args.isEmpty) {
      // list
      if (_aliases.isEmpty) {
        historyProvider.addOutput('No aliases defined');
      } else {
        _aliases.forEach((k, v) => historyProvider.addOutput('$k => $v'));
      }
      return;
    }
    final sub = args[0];
    if (sub == 'add' && args.length >= 3) {
      final name = args[1];
      final command = args.sublist(2).join(' ');
      _aliases[name] = command;
      historyProvider.addOutput('Alias added: $name => $command');
      return;
    }
    if (sub == 'remove' && args.length >= 2) {
      final name = args[1];
      _aliases.remove(name);
      historyProvider.addOutput('Alias removed: $name');
      return;
    }
    historyProvider.addError('Usage: alias [add|remove] <name> <command>');
  }

  void _cmdSettings() {
    // navigate to settings screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    historyProvider.addOutput('Opened settings (placeholder)');
  }

  void _cmdUsage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UsageStatsScreen()));
    historyProvider.addOutput('Opened usage stats');
  }

  Future<void> _cmdLock(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError('Invalid usage. Usage: lock <app> [minutes]');
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
      historyProvider.addError('No app matching "$query"');
      return;
    }
    final pkgName = match['packageName'] as String?;
    if (pkgName == null) {
      historyProvider.addError('No packageName for matched app');
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
      historyProvider.addError('Failed to block $pkgName: ${e.toString()}');
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
          'Failed to fetch blocked apps: ${e.toString()}',
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
      historyProvider.addError('No packageName for matched app');
      return;
    }

    try {
      await native.removeBlockedApp(pkgName);
      historyProvider.addOutput('Unblocked $pkgName');
    } catch (e) {
      historyProvider.addError('Failed to unblock $pkgName: ${e.toString()}');
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
      historyProvider.addError('Unknown mode: $mode. Use on|off');
    } catch (e) {
      historyProvider.addError('Error toggling grayscale: ${e.toString()}');
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
        'Failed to fetch notifications: ${e.toString()}',
      );
    }
  }

  Future<void> _cmdEssential(List<String> args) async {
    if (args.isEmpty) {
      historyProvider.addError('Usage: essential [add|remove|list] <app>');
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
        historyProvider.addError('Failed to fetch essentials: ${e.toString()}');
      }
      return;
    }
    if (args.length < 2) {
      historyProvider.addError('Usage: essential [add|remove|list] <app>');
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
        historyProvider.addError('Unknown subcommand: $sub');
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
    if (mode == 'on') {
      // Placeholder: enable focus mode (actual blocking will be implemented later)
      historyProvider.addOutput(
        'Focus mode activated. All non-essential apps blocked.',
      );
      return;
    }
    if (mode == 'off') {
      // Placeholder: disable focus mode
      historyProvider.addOutput('Focus mode disabled.');
      return;
    }
    historyProvider.addError('Unknown mode: $mode. Use on|off');
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
          historyProvider.addError('Invalid date: $a');
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

    int i = 0;
    for (final e in provider.entries) {
      i++;
      final mins = (e.totalTimeInForeground / 60000).round();
      final label = mins >= 60
          ? '${(mins / 60).toStringAsFixed(1)}h'
          : '${mins}m';
      // try to resolve app name from installed apps
      final apps = await native.getInstalledApps();
      final found = apps.firstWhere(
        (a) => (a['packageName'] ?? '') == e.packageName,
        orElse: () => {},
      );
      final name = found.isEmpty
          ? e.packageName
          : (found['name'] ?? e.packageName);
      historyProvider.addOutput('$i. $name – $label');
      if (i >= 50) break; // safety
    }
  }
}
