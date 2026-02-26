import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auraless/providers/lifecycle_provider.dart';
import 'package:auraless/providers/system_info_provider.dart';
import 'package:auraless/core/native_channel_service.dart' as svc;

class SystemInfoPanel extends StatefulWidget {
  const SystemInfoPanel({super.key});

  @override
  State<SystemInfoPanel> createState() => _SystemInfoPanelState();
}

class _SystemInfoPanelState extends State<SystemInfoPanel> {
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to lifecycle provider to refresh on resume and start periodic updates
    if (!_listening) {
      try {
        final lifecycle = Provider.of<LifecycleProvider>(context);
        lifecycle.addListener(() {
          if (lifecycle.currentState == AppLifecycleState.resumed) {
            try {
              final sip = Provider.of<SystemInfoProvider>(
                context,
                listen: false,
              );
              sip.refreshInfo();
            } catch (_) {}
          }
        });

        // Start periodic updates when the panel is first added
        try {
          final sip = Provider.of<SystemInfoProvider>(context, listen: false);
          sip.startPeriodic();
        } catch (_) {}

        _listening = true;
      } catch (e) {
        // provider not available
      }
    }
  }

  Widget _line(String label, dynamic value) {
    return Text(
      '[OK] $label: $value',
      style: const TextStyle(
        color: Color(0xFF00FF00),
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Try to resolve provider; if missing (tests or isolated widget), fall back to one-off native fetch
    try {
      // Ensure provider exists without creating an unused local
      Provider.of<SystemInfoProvider>(context, listen: false);
      return Consumer<SystemInfoProvider>(
        builder: (context, sip, _) {
          if (sip.isLoading && sip.info == null) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final info = sip.info;
          if (info == null) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('[OK] System info unavailable')),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('Model', info['model'] ?? '-'),
              _line(
                'Android',
                '${info['androidVersion']} (API ${info['apiLevel']})',
              ),
              _line('Kernel', info['kernelVersion'] ?? '-'),
              _line('Uptime (min)', info['uptimeMinutes'] ?? '-'),
              _line('Battery %', info['batteryPercent'] ?? '-'),
              _line('RAM used/total', '${info['ramUsed']}/${info['ramTotal']}'),
              _line(
                'Storage used/total',
                '${info['storageUsed']}/${info['storageTotal']}',
              ),
              _line('Network', info['networkType'] ?? '-'),
            ],
          );
        },
      );
    } catch (_) {
      // Provider not found — fallback to a single native fetch to avoid throwing in tests
      Future<Map<String, dynamic>?> fetchSafe() async {
        try {
          final v = await svc.NativeChannelService().getSystemInfo();
          return v;
        } catch (_) {
          return null;
        }
      }

      return FutureBuilder<Map<String, dynamic>?>(
        future: fetchSafe(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final info = snap.data;
          if (info == null) {
            return const SizedBox(
              height: 60,
              child: Center(child: Text('[OK] System info unavailable')),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('Model', info['model'] ?? '-'),
              _line(
                'Android',
                '${info['androidVersion']} (API ${info['apiLevel']})',
              ),
              _line('Kernel', info['kernelVersion'] ?? '-'),
              _line('Uptime (min)', info['uptimeMinutes'] ?? '-'),
              _line('Battery %', info['batteryPercent'] ?? '-'),
              _line('RAM used/total', '${info['ramUsed']}/${info['ramTotal']}'),
              _line(
                'Storage used/total',
                '${info['storageUsed']}/${info['storageTotal']}',
              ),
              _line('Network', info['networkType'] ?? '-'),
            ],
          );
        },
      );
    }
  }
}
