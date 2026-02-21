import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/terminal_home_screen.dart';
import 'providers/lifecycle_provider.dart';
import 'core/hive_service.dart';

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
    return ChangeNotifierProvider(
      create: (_) => LifecycleProvider(),
      child: MaterialApp(
        title: 'Mini',
        theme: ThemeData.dark(),
        home: const MainScreen(),
      ),
    );
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
