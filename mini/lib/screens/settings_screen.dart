import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auraless/providers/theme_provider.dart';
import 'digital_wellbeing_settings.dart';
import 'appearance_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Terminal Configuration',
      'Digital Wellbeing',
      'Notifications',
      'Appearance',
      'Permissions',
      'About',
    ];

    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(color: colors.primaryText, fontFamily: 'monospace'),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Colors.transparent, height: 8),
        itemBuilder: (context, index) {
          final name = categories[index];
          return ListTile(
            tileColor: colors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: Text(
              name,
              style: TextStyle(
                color: colors.primaryText,
                fontFamily: 'monospace',
              ),
            ),
            onTap: () {
              if (name == 'Digital Wellbeing') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DigitalWellbeingSettings(),
                  ),
                );
                return;
              }
              if (name == 'Appearance') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppearanceSettings()),
                );
                return;
              }
            },
          );
        },
      ),
    );
  }
}
