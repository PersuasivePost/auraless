import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import 'package:mini/constants/colors.dart';
import 'package:mini/features/terminal/widgets/system_info_panel.dart';
import 'package:mini/features/terminal/widgets/terminal_input.dart';
import 'package:mini/core/command_parser.dart';
import 'package:mini/core/native_channel_service.dart';
import 'package:mini/providers/terminal_history_provider.dart';
import 'package:mini/screens/settings_screen.dart';

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

  void _showRecentCommands() {
    if (_overlayEntry != null) return;
    final provider = Provider.of<TerminalHistoryProvider>(
      context,
      listen: false,
    );
    final recent = provider.commandHistory.reversed.take(5).toList();
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
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
                            return InkWell(
                              onTap: () {
                                _inputController.text = c;
                                _inputController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(offset: c.length),
                                    );
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
    // show one-time welcome message after setup completes
    try {
      final settings = Hive.box('settings');
      final isSetupComplete =
          settings.get('isSetupComplete', defaultValue: false) as bool;
      final welcomeShown =
          settings.get('welcomeShown', defaultValue: false) as bool;
      if (isSetupComplete && !welcomeShown) {
        final provider = Provider.of<TerminalHistoryProvider>(
          context,
          listen: false,
        );
        provider.addOutput(
          "Welcome to DevLauncher v1.0.0. Type 'help' to get started.",
        );
        settings.put('welcomeShown', true);
      }
    } catch (e) {
      // Hive may not be initialized in tests; ignore failures
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          onLongPress: () {
            // Navigate to settings on long press anywhere on the terminal
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // System info panel
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SystemInfoPanel(),
              ),
              const Divider(color: Colors.transparent, height: 4),

              // History
              Expanded(
                child: Consumer<TerminalHistoryProvider>(
                  builder: (context, history, _) {
                    final entries = history.entries;
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        // when reverse is true, show from the end
                        final entry = entries[entries.length - 1 - index];
                        Color color;
                        switch (entry.type) {
                          case 'command':
                            color = primaryGreen;
                            break;
                          case 'error':
                            color = errorRed;
                            break;
                          default:
                            color = outputGreen;
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

              // Input anchored at bottom
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                color: background,
                child: TerminalInput(
                  controller: _inputController,
                  onShowHistory: _showRecentCommands,
                  onCommandSubmitted: (cmd) async {
                    final provider = Provider.of<TerminalHistoryProvider>(
                      context,
                      listen: false,
                    );
                    provider.addCommand(cmd);

                    // Execute the command using CommandParser so commands run real logic
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
    );
  }
}
