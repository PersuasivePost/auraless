import 'package:flutter/material.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'colors.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  final _native = NativeChannelService();
  bool _grayscale = false;
  bool _loading = false;

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      final ok = value
          ? await _native.enableGrayscale()
          : await _native.disableGrayscale();
      if (ok) {
        if (!mounted) return;
        setState(() => _grayscale = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grayscale ${value ? 'enabled' : 'disabled'}'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission denied. Run: adb shell pm grant <your.app.package> android.permission.WRITE_SECURE_SETTINGS',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling grayscale: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          'Appearance',
          style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            title: Text(
              'Grayscale',
              style: TextStyle(color: kPrimaryGreen, fontFamily: 'monospace'),
            ),
            subtitle: const Text(
              'Reduce color to grayscale (requires adb grant on some devices)',
            ),
            trailing: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                : Switch(value: _grayscale, onChanged: (v) => _toggle(v)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final enabled = await _native.isGrayscaleEnabled();
      if (mounted) setState(() => _grayscale = enabled);
    } catch (_) {
      if (mounted) setState(() => _grayscale = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
