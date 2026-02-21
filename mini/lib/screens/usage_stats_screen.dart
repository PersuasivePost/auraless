import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usage_stats_provider.dart';

class UsageStatsScreen extends StatefulWidget {
  const UsageStatsScreen({super.key});

  @override
  State<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends State<UsageStatsScreen> {
  late UsageStatsProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = Provider.of<UsageStatsProvider>(context);
    // load today's usage
    _provider.loadForDay(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final entries = _provider.entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Usage - Today')),
      body: _provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final secs = e.totalTimeInForeground ~/ 1000;
                return ListTile(
                  title: Text(e.packageName),
                  subtitle: Text('$secs sec foreground'),
                );
              },
            ),
    );
  }
}
