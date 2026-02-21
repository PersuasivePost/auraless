// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mini/main.dart';
import 'package:mini/screens/terminal_home_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the LauncherApp and verify the terminal screen is present.
    await tester.pumpWidget(const LauncherApp());
    await tester.pumpAndSettle();

    // TerminalHomeScreen should be in the tree.
    expect(find.byType(TerminalHomeScreen), findsOneWidget);
  });
}
