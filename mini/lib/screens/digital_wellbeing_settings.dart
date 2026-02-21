import 'package:flutter/material.dart';
import 'package:mini/core/hive_service.dart';

class DigitalWellbeingSettings extends StatefulWidget {
  const DigitalWellbeingSettings({super.key});

  @override
  State<DigitalWellbeingSettings> createState() =>
      _DigitalWellbeingSettingsState();
}

class _DigitalWellbeingSettingsState extends State<DigitalWellbeingSettings> {
  late int _delaySeconds;

  @override
  void initState() {
    super.initState();
    _delaySeconds =
        HiveService.getSetting('mindful_delay_seconds', defaultValue: 30)
            as int;
  }

  Future<void> _save() async {
    await HiveService.setSetting('mindful_delay_seconds', _delaySeconds);
    try {
      // also persist to native prefs as a fallback
      // ignore: avoid_dynamic_calls
      // NativeChannelService not imported here; this is optional and can be wired later from main/provider
    } catch (e) {
      // ignore
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Wellbeing')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mindful delay (seconds)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 5,
                    max: 120,
                    divisions: 23,
                    value: _delaySeconds.toDouble(),
                    label: '$_delaySeconds',
                    onChanged: (v) => setState(() => _delaySeconds = v.toInt()),
                  ),
                ),
                Text('$_delaySeconds s'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
