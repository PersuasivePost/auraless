import 'package:flutter/foundation.dart';

class HistoryEntry {
  final String type; // 'command' | 'output' | 'error'
  final String text;
  final DateTime timestamp;

  HistoryEntry({required this.type, required this.text})
    : timestamp = DateTime.now();
}

class TerminalHistoryProvider extends ChangeNotifier {
  final List<HistoryEntry> entries = [];
  final List<String> commandHistory = [];
  int historyIndex = -1; // -1 means no selection

  void addCommand(String cmd) {
    entries.add(HistoryEntry(type: 'command', text: cmd));
    commandHistory.add(cmd);
    historyIndex = commandHistory.length; // reset index to end
    notifyListeners();
  }

  void addOutput(String out) {
    entries.add(HistoryEntry(type: 'output', text: out));
    notifyListeners();
  }

  void addError(String err) {
    entries.add(HistoryEntry(type: 'error', text: err));
    notifyListeners();
  }

  void clear() {
    entries.clear();
    notifyListeners();
  }

  String? getPreviousCommand() {
    if (commandHistory.isEmpty) return null;
    if (historyIndex > 0) historyIndex--;
    if (historyIndex < 0) historyIndex = 0;
    return commandHistory[historyIndex];
  }

  String? getNextCommand() {
    if (commandHistory.isEmpty) return null;
    if (historyIndex < commandHistory.length - 1) historyIndex++;
    if (historyIndex >= commandHistory.length) {
      historyIndex = commandHistory.length;
      return '';
    }
    return commandHistory[historyIndex];
  }
}
