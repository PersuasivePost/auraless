import 'package:flutter/material.dart';
import 'colors.dart';

class HiddenAppList extends StatelessWidget {
  final List<String> favorites;
  final List<String> allApps;

  const HiddenAppList({
    Key? key,
    required this.favorites,
    required this.allApps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAVORITES',
                style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              ...favorites.map((name) => _appRow(name)),
              const SizedBox(height: 12),
              Text(
                'ALL APPS',
                style: TextStyle(color: kDimGreen, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: allApps.length,
                  itemBuilder: (context, index) => _appRow(allApps[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appRow(String name) {
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: () {},
        onLongPress: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}
