import 'dart:async';

import 'package:flutter/material.dart';
import 'colors.dart';

class TerminalHomeScreen extends StatefulWidget {
  const TerminalHomeScreen({Key? key}) : super(key: key);

  @override
  State<TerminalHomeScreen> createState() => _TerminalHomeScreenState();
}

class _TerminalHomeScreenState extends State<TerminalHomeScreen> {
  final List<String> _history = List<String>.generate(
    20,
    (i) => i % 5 == 0 ? 'Error: failed to run command #$i' : 'Output line #$i',
  );
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      setState(() => _showCursor = !_showCursor);
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      // Placeholder system info
                      '12:34  •  85%  •  Wi‑Fi',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // small accent marker
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: kAccentGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.transparent, height: 4),
            // History
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final text = _history[index];
                  final isError = text.startsWith('Error');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isError ? kErrorRed : kOutputGreen,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Input line
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              color: kBackgroundColor,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '> ',
                    style: TextStyle(
                      color: kPrimaryGreen,
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // manual keyboard activation
                        _focusNode.requestFocus();
                      },
                      child: AbsorbPointer(
                        absorbing: false,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: Colors.transparent,
                            height: 0.1,
                          ),
                          cursorColor: kPrimaryGreen,
                          cursorWidth: 2,
                          showCursor: false,
                          decoration: const InputDecoration.collapsed(
                            hintText: null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Visual input + blinking cursor
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      children: [
                        // visible text (mirror)
                        Text(
                          _controller.text,
                          style: TextStyle(
                            color: kPrimaryGreen,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                        // blinking cursor
                        AnimatedOpacity(
                          opacity: _showCursor ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 10,
                            height: 20,
                            color: kPrimaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
