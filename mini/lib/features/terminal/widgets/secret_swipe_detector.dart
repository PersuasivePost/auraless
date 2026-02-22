import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SecretSwipeDetector
/// - Wraps child and detects right swipes (horizontal only)
/// - Increments an internal counter on each right swipe where horizontal movement
///   dominates vertical movement. Ignores diagonal gestures.
/// - Resets the counter after 8 seconds of inactivity or when any other swipe
///   direction occurs.
/// - When counter reaches 6, calls [onSecretUnlocked] and gives haptic feedback.
/// - Exposes a public [resetCounter] method on the State for manual resets.
class SecretSwipeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onSecretUnlocked;
  final int requiredSwipes;
  final Duration timeout;

  const SecretSwipeDetector({
    super.key,
    required this.child,
    required this.onSecretUnlocked,
    this.requiredSwipes = 6,
    this.timeout = const Duration(seconds: 8),
  });

  @override
  SecretSwipeDetectorState createState() => SecretSwipeDetectorState();
}

class SecretSwipeDetectorState extends State<SecretSwipeDetector> {
  int _count = 0;
  Timer? _timeoutTimer;
  Offset? _startPosition;

  void _resetTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.timeout, () {
      setState(() {
        _count = 0;
      });
    });
  }

  /// Public method to reset the counter manually
  void resetCounter() {
    _timeoutTimer?.cancel();
    setState(() {
      _count = 0;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // nothing; we'll evaluate at end
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startPosition == null) return;
    // velocity not reliable for direction; compare last and start positions via gesture arena
    // We'll use the global position from the gesture: can't access here, so use velocity for direction
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    // If horizontal dominates vertical and velocity to right
    final horizontalDominant = vx.abs() > vy.abs();
    final isRight = vx > 100; // require a minimum velocity to avoid tiny moves

    // debug log
    // ignore: avoid_print
    print(
      'SecretSwipeDetector.onPanEnd vx=$vx vy=$vy horizontalDominant=$horizontalDominant isRight=$isRight countBefore=$_count',
    );

    if (horizontalDominant && isRight) {
      setState(() {
        _count++;
      });
      HapticFeedback.heavyImpact();
      _resetTimer();
      if (_count >= widget.requiredSwipes) {
        // ignore: avoid_print
        print('SecretSwipeDetector: unlocked (count=$_count)');
        widget.onSecretUnlocked();
        // reset after triggering
        setState(() {
          _count = 0;
        });
        _timeoutTimer?.cancel();
      }
    } else if (horizontalDominant && !isRight) {
      // left swipe -> reset
      setState(() {
        _count = 0;
      });
      _timeoutTimer?.cancel();
    } else {
      // vertical or diagonal -> ignore but reset
      setState(() {
        _count = 0;
      });
      _timeoutTimer?.cancel();
    }
    _startPosition = null;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: widget.child,
    );
  }
}
