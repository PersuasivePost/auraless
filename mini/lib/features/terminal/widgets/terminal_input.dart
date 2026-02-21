import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini/constants/colors.dart';

/// TerminalInput: a single-line input with a fixed prompt prefix (" > ")
/// - autocorrect and suggestions disabled
/// - exposes onCommandSubmitted callback
class TerminalInput extends StatefulWidget {
  final void Function(String) onCommandSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  final VoidCallback? onShowHistory;

  const TerminalInput({
    super.key,
    required this.onCommandSubmitted,
    this.controller,
    this.focusNode,
    this.onShowHistory,
  });

  @override
  State<TerminalInput> createState() => _TerminalInputState();
}

class _TerminalInputState extends State<TerminalInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      setState(() => _showCursor = !_showCursor);
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onCommandSubmitted(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '> ',
            style: const TextStyle(
              color: primaryGreen,
              fontFamily: 'monospace',
              fontSize: 16,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
                // ensure IME opens when focus is requested
                SystemChannels.textInput.invokeMethod('TextInput.show');
              },
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                      cursorColor: primaryGreen,
                      cursorWidth: 2,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration.collapsed(
                        hintText: null,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  // history toggle button
                  IconButton(
                    onPressed: widget.onShowHistory,
                    icon: const Icon(Icons.history, color: primaryGreen),
                    splashRadius: 20,
                    tooltip: 'Recent commands',
                  ),
                  // blinking block cursor next to text (visual enhancement)
                  AnimatedOpacity(
                    opacity: _showCursor ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 8,
                      height: 20,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
