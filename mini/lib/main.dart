import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/terminal_home_screen.dart';
import 'screens/setup_wizard.dart';
import 'core/hive_service.dart';
import 'providers/lifecycle_provider.dart';
import 'core/native_channel_service.dart';
import 'providers/usage_stats_provider.dart';
import 'providers/apps_provider.dart';
import 'providers/terminal_history_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const LauncherApp());
}

class LauncherApp extends StatefulWidget {
  const LauncherApp({super.key});

  @override
  State<LauncherApp> createState() => _LauncherAppState();
}

class _LauncherAppState extends State<LauncherApp> with WidgetsBindingObserver {
  bool _checksStarted = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Detect when app resumes (foreground)
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
    super.didChangeAppLifecycleState(state);
  }

  void onResume() {
    // Placeholder for resume work: refresh system info, reset swipe counter, refresh app list
    debugPrint(
      'LauncherApp: onResume called - refresh system info and app list (placeholder)',
    );
    // Notify provider
    try {
      final provider = Provider.of<LifecycleProvider>(context, listen: false);
      provider.onResume();
    } catch (e) {
      // Provider not available yet - ignore for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final native = NativeChannelService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LifecycleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UsageStatsProvider(native)),
        ChangeNotifierProvider(create: (_) => AppsProvider(native)),
        ChangeNotifierProvider(create: (_) => TerminalHistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'AuraLess',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: theme.mode == AppThemeMode.system
                ? ThemeMode.system
                : (theme.mode == AppThemeMode.light
                      ? ThemeMode.light
                      : ThemeMode.dark),
            home:
                HiveService.getSetting(
                      'isSetupComplete',
                      defaultValue: false,
                    ) ==
                    true
                ? const MainScreen()
                : const SetupWizard(),
          );
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checksStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final lifecycle = Provider.of<LifecycleProvider>(
            context,
            listen: false,
          );
          final history = Provider.of<TerminalHistoryProvider>(
            context,
            listen: false,
          );
          lifecycle.startPeriodicChecks(history);
          _checksStarted = true;
        } catch (_) {}
      });
    }
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Swallow back button when on the terminal screen using WillPopScope
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Do nothing when back is pressed (swallow event)
        return false;
      },
      child: const TerminalHomeScreen(),
    );
  }
}
