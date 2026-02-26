import 'package:flutter/material.dart';

class AppColors {
  final Color background;
  final Color primaryText;
  final Color outputText;
  final Color dimText;
  final Color accent;
  final Color error;

  const AppColors({
    required this.background,
    required this.primaryText,
    required this.outputText,
    required this.dimText,
    required this.accent,
    required this.error,
  });

  static const dark = AppColors(
    background: Color(0xFF000000),
    primaryText: Color(0xFF00FF00),
    outputText: Color(0xFF00CC00),
    dimText: Color(0xFF008800),
    accent: Color(0xFF00AA00),
    error: Color(0xFFFF4444),
    // add warning color
    // (this field reuses 'accent' in the constructor but we add color constant below)
  );

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    primaryText: Color(0xFF006600),
    outputText: Color(0xFF004400),
    dimText: Color(0xFF888888),
    accent: Color(0xFF00AA00),
    error: Color(0xFFFF4444),
  );
}

// Backwards-compatible constants defaulting to dark theme values.
final Color background = AppColors.dark.background;
final Color primaryGreen = AppColors.dark.primaryText;
final Color outputGreen = AppColors.dark.outputText;
final Color dimGreen = AppColors.dark.dimText;
final Color accentGreen = AppColors.dark.accent;
final Color errorRed = AppColors.dark.error;
final Color warningYellow = const Color(0xFFFFC107); // amber
