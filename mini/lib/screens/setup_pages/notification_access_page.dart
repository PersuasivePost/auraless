import 'package:flutter/material.dart';
import 'package:auraless/core/native_channel_service.dart';
import '../colors.dart';

class NotificationAccessPage extends StatefulWidget {
  final VoidCallback onNext;
  const NotificationAccessPage({super.key, required this.onNext});

  @override
  State<NotificationAccessPage> createState() => _NotificationAccessPageState();
}

class _NotificationAccessPageState extends State<NotificationAccessPage> {
  final _native = NativeChannelService();
  bool _enabled = false;

  Future<void> _check() async {
    final ok = await _native.isNotificationListenerEnabled().catchError(
      (_) => false,
    );
    if (!mounted) return;
    setState(() => _enabled = ok);
  }

  Future<void> _openSettings() async {
    await _native.openNotificationListenerSettings();
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
            'Notification Access',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Allow notification access so DevLauncher can capture digests.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: _openSettings,
            child: const Text('Grant Notification Access'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
            onPressed: _enabled ? widget.onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
