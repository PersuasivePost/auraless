import 'package:flutter/material.dart';
import 'colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Colors.transparent, height: 8),
        itemBuilder: (context, index) {
          final name = categories[index];
          return ListTile(
            tileColor: kBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: Text(
              name,
              style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}
