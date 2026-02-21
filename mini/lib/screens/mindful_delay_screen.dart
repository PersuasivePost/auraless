import 'dart:async';

import 'package:flutter/material.dart';
import 'colors.dart';

class MindfulDelayScreen extends StatefulWidget {
  final String appName;
  final int seconds;

  const MindfulDelayScreen({
    Key? key,
    this.appName = 'Target App',
    this.seconds = 30,
  }) : super(key: key);

  @override
  State<MindfulDelayScreen> createState() => _MindfulDelayScreenState();
}

class _MindfulDelayScreenState extends State<MindfulDelayScreen> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_remaining / widget.seconds);

    return WillPopScope(
      onWillPop: () async {
        // disable back while timer running
        return _remaining == 0;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.appName,
                  style: TextStyle(
                    color: kPrimaryGreen,
                    fontSize: 32,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _remaining == 0 ? 1 : progress,
                        color: kAccentGreen,
                        backgroundColor: kDimGreen,
                        strokeWidth: 8,
                      ),
                      Text(
                        _remaining > 0 ? '$_remaining' : 'Ready',
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontSize: 28,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_remaining == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentGreen,
                        ),
                        onPressed: () {
                          // placeholder: open the app
                        },
                        child: const Text('Open App'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                        ),
                        onPressed: () {
                          // back to launcher
                          Navigator.of(context).pop();
                        },
                        child: const Text('Back to Launcher'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
