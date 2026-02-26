import 'package:flutter/material.dart';
import 'colors.dart';

class RecentCommandsPopup extends StatelessWidget {
  final List<String> commands;
  final VoidCallback? onDismiss;
  final void Function(String)? onCommandSelected;

  const RecentCommandsPopup({
    super.key,
    required this.commands,
    this.onDismiss,
    this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Detect taps outside the popup
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              if (onDismiss != null) {
                onDismiss!();
              }
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        Center(
          child: Material(
            color: kBackgroundColor,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent commands',
                    style: TextStyle(
                      color: kPrimaryGreen,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...commands.take(5).map((c) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // notify parent and then dismiss
                        if (onCommandSelected != null) onCommandSelected!(c);
                        Navigator.of(context).pop();
                        if (onDismiss != null) onDismiss!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: kOutputGreen,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onDismiss != null) onDismiss!();
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
