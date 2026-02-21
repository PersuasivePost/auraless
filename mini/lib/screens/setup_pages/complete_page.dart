import 'package:flutter/material.dart';
import '../colors.dart';
import 'package:auraless/core/hive_service.dart';
import 'package:auraless/core/native_channel_service.dart';

class CompletePage extends StatefulWidget {
  final VoidCallback onFinish;
  const CompletePage({super.key, required this.onFinish});

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  final _native = NativeChannelService();
  bool _usage = false;
  bool _accessibility = false;
  bool _notifications = false;
  bool _grayscale = false;
  int _blockedCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
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
      final gray = await _native.isGrayscaleEnabled().catchError((_) => false);
      final blocked = HiveService.getBlockedApps();
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _accessibility = acc;
        _notifications = notif;
        _grayscale = gray;
        _blockedCount = blocked.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _finish() async {
    await HiveService.setSetting('isSetupComplete', true);
    widget.onFinish();
  }

  Widget _statusRow(String label, bool ok, {String? note}) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          color: ok ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: kPrimaryGreen)),
              if (note != null)
                Text(note, style: TextStyle(color: kOutputGreen, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Setup Complete',
                  style: TextStyle(
                    color: kPrimaryGreen,
                    fontSize: 24,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Summary of setup:',
                  style: TextStyle(color: kOutputGreen),
                ),
                const SizedBox(height: 16),
                _statusRow('Default launcher set', true),
                const SizedBox(height: 12),
                _statusRow(
                  'Usage access',
                  _usage,
                  note: _usage ? null : 'Used for app usage stats',
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Accessibility service',
                  _accessibility,
                  note: _accessibility ? null : 'Needed for blocking behavior',
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Notification access',
                  _notifications,
                  note: _notifications
                      ? null
                      : 'Needed to capture and digest notifications',
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Grayscale (ADB)',
                  _grayscale,
                  note: _grayscale
                      ? null
                      : 'Optional - grants WRITE_SECURE_SETTINGS',
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Blocked apps configured',
                  _blockedCount > 0,
                  note: '$_blockedCount apps blocked',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentGreen,
                  ),
                  onPressed: _finish,
                  child: const Text('Launch DevLauncher'),
                ),
              ],
            ),
    );
  }
}
