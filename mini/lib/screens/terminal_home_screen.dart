import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Hive import removed — no startup welcome message or settings access needed here.

import 'package:auraless/constants/colors.dart';
import 'package:auraless/providers/theme_provider.dart';
import 'package:auraless/features/terminal/widgets/system_info_panel.dart';
import 'package:auraless/features/terminal/widgets/terminal_input.dart';
import 'package:auraless/features/terminal/widgets/secret_swipe_detector.dart';
import 'package:auraless/core/command_parser.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'package:auraless/providers/terminal_history_provider.dart';
import 'package:auraless/screens/settings_screen.dart';
import 'package:auraless/providers/system_info_provider.dart';

class TerminalHomeScreen extends StatefulWidget {
  const TerminalHomeScreen({super.key});

  @override
  State<TerminalHomeScreen> createState() => _TerminalHomeScreenState();
}

class _TerminalHomeScreenState extends State<TerminalHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _listening = false;
  final TextEditingController _inputController = TextEditingController();
  OverlayEntry? _overlayEntry;

  Future<void> _submitCommandFromPopup(
    BuildContext screenContext,
    String cmd,
  ) async {
    final provider = Provider.of<TerminalHistoryProvider>(
      screenContext,
      listen: false,
    );
    provider.addCommand(cmd);

    final native = NativeChannelService();
    final parser = CommandParser(
      context: screenContext,
      native: native,
      historyProvider: provider,
    );
    // fire and forget - UI will continue
    Future.microtask(() => parser.execute(cmd));
  }

  void _showRecentCommands() {
    if (_overlayEntry != null) return;
    final provider = Provider.of<TerminalHistoryProvider>(
      context,
      listen: false,
    );
    final recent = provider.commandHistory.reversed.take(5).toList();
    final overlay = Overlay.of(context);

    final screenContext = context;
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 80,
                    child: Material(
                      color: background,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: recent.map((c) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                // Set input text, submit command, then remove overlay
                                _inputController.text = c;
                                _inputController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: c.length),
                                    );
                                _submitCommandFromPopup(screenContext, c);
                                _removeOverlay();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      final provider = Provider.of<TerminalHistoryProvider>(context);
      provider.addListener(_onHistoryUpdated);
      _listening = true;
    }
    // No startup welcome message is shown on terminal by design.
    // Ensure system info periodic refresh is started when terminal is visible
    try {
      final sip = Provider.of<SystemInfoProvider>(context, listen: false);
      sip.startPeriodic();
    } catch (_) {}
  }

  void _onHistoryUpdated() {
    // scroll to bottom (reverse: true uses offset 0)
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_listening) {
      try {
        Provider.of<TerminalHistoryProvider>(
          context,
          listen: false,
        ).removeListener(_onHistoryUpdated);
      } catch (_) {}
    }
    // stop system info periodic updates when leaving the terminal
    try {
      final sip = Provider.of<SystemInfoProvider>(context, listen: false);
      sip.stopPeriodic();
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SecretSwipeDetector(
          onSecretUnlocked: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            onLongPress: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SystemInfoPanel(),
                ),
                const Divider(color: Colors.transparent, height: 4),

                Expanded(
                  child: Consumer<TerminalHistoryProvider>(
                    builder: (context, history, _) {
                      final entries = history.entries;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[entries.length - 1 - index];
                          Color color;
                          switch (entry.type) {
                            case 'command':
                              color = colors.primaryText;
                              break;
                            case 'error':
                              color = colors.error;
                              break;
                            case 'warning':
                              color = warningYellow;
                              break;
                            default:
                              color = colors.outputText;
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              entry.text,
                              style: TextStyle(
                                color: color,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  color: colors.background,
                  child: TerminalInput(
                    controller: _inputController,
                    onShowHistory: _showRecentCommands,
                    onCommandSubmitted: (cmd) async {
                      final provider = Provider.of<TerminalHistoryProvider>(
                        context,
                        listen: false,
                      );
                      provider.addCommand(cmd);

                      final native = NativeChannelService();
                      final parser = CommandParser(
                        context: context,
                        native: native,
                        historyProvider: provider,
                      );
                      await parser.execute(cmd);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
