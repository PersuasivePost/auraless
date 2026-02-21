import 'package:flutter/material.dart';
import 'package:mini/core/native_channel_service.dart';
import '../colors.dart';

class SetDefaultPage extends StatelessWidget {
  final VoidCallback onNext;
  const SetDefaultPage({super.key, required this.onNext});

  Future<void> _openHomePicker() async {
    final native = NativeChannelService();
    await native.openHomePicker();
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
            'Set as Default Home',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To make DevLauncher your default home app, open the system picker and choose DevLauncher.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: _openHomePicker,
            child: const Text('Set as Default Home'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
