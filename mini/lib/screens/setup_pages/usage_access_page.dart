import 'package:flutter/material.dart';
import 'package:mini/core/native_channel_service.dart';
import '../colors.dart';

class UsageAccessPage extends StatefulWidget {
  final VoidCallback onNext;
  const UsageAccessPage({super.key, required this.onNext});

  @override
  State<UsageAccessPage> createState() => _UsageAccessPageState();
}

class _UsageAccessPageState extends State<UsageAccessPage> {
  final _native = NativeChannelService();
  bool _granted = false;

  Future<void> _check() async {
    final ok = await _native.hasUsageStatsPermission().catchError((_) => false);
    if (!mounted) return;
    setState(() => _granted = ok);
  }

  Future<void> _openSettings() async {
    await _native.requestUsageStatsPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    await _check();
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Usage Access',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enable usage access to allow DevLauncher to show digital wellbeing stats.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: _openSettings,
            child: const Text('Grant Usage Access'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
            onPressed: _granted ? widget.onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
