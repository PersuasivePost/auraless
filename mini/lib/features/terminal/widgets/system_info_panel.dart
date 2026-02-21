import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini/core/native_channel_service.dart' as svc;
import 'package:mini/providers/lifecycle_provider.dart';

class SystemInfoPanel extends StatefulWidget {
  const SystemInfoPanel({super.key});

  @override
  State<SystemInfoPanel> createState() => _SystemInfoPanelState();
}

class _SystemInfoPanelState extends State<SystemInfoPanel> {
  final _service = svc.NativeChannelService();
  Map<String, dynamic>? _info;
  bool _loading = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    // initial load
    _fetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to lifecycle provider to refresh on resume
    if (!_listening) {
      try {
        final lifecycle = Provider.of<LifecycleProvider>(context);
        lifecycle.addListener(() {
          if (lifecycle.currentState == AppLifecycleState.resumed) _fetch();
        });
        _listening = true;
      } catch (e) {
        // provider not available
      }
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
    });
    try {
      final info = await _service.getSystemInfo();
      setState(() {
        _info = info;
      });
    } catch (e) {
      // ignore errors for now
    } finally {
      setState(() {
        _loading = false;
      });
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
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_info == null) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('[OK] System info unavailable')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line('Model', _info!['model'] ?? '-'),
        _line(
          'Android',
          '${_info!['androidVersion']} (API ${_info!['apiLevel']})',
        ),
        _line('Kernel', _info!['kernelVersion'] ?? '-'),
        _line('Uptime (min)', _info!['uptimeMinutes'] ?? '-'),
        _line('Battery %', _info!['batteryPercent'] ?? '-'),
        _line('RAM used/total', '${_info!['ramUsed']}/${_info!['ramTotal']}'),
        _line(
          'Storage used/total',
          '${_info!['storageUsed']}/${_info!['storageTotal']}',
        ),
        _line('Network', _info!['networkType'] ?? '-'),
      ],
    );
  }
}
