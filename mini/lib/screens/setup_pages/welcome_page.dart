import 'package:flutter/material.dart';
import '../colors.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text('Logo', style: TextStyle(color: kPrimaryGreen)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to DevLauncher',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A minimal, privacy-friendly launcher with focus tools and a terminal-first UI.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: onNext,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
