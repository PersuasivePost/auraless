import 'package:flutter/material.dart';
import 'package:mini/core/native_channel_service.dart';
import '../colors.dart';

class AccessibilityPage extends StatefulWidget {
  final VoidCallback onNext;
  const AccessibilityPage({super.key, required this.onNext});

  @override
  State<AccessibilityPage> createState() => _AccessibilityPageState();
}

class _AccessibilityPageState extends State<AccessibilityPage> {
  final _native = NativeChannelService();
  bool _enabled = false;

  Future<void> _check() async {
    final ok = await _native.isAccessibilityServiceEnabled().catchError(
      (_) => false,
    );
    if (!mounted) return;
    setState(() => _enabled = ok);
  }

  Future<void> _openSettings() async {
    await _native.openAccessibilitySettings();
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
            'Accessibility',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enable the accessibility service to allow app blocking features.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: _openSettings,
            child: const Text('Enable Accessibility'),
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
