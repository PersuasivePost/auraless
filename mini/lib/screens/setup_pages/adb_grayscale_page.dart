import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mini/core/native_channel_service.dart';
import '../colors.dart';

class AdbGrayscalePage extends StatefulWidget {
  final VoidCallback onNext;
  const AdbGrayscalePage({super.key, required this.onNext});

  @override
  State<AdbGrayscalePage> createState() => _AdbGrayscalePageState();
}

class _AdbGrayscalePageState extends State<AdbGrayscalePage> {
  final _native = NativeChannelService();
  bool _granted = false;
  bool _testing = false;
  bool _success = false;

  final String _adbCommand =
      'adb shell pm grant <your.app.package> android.permission.WRITE_SECURE_SETTINGS';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final enabled = await _native.isGrayscaleEnabled().catchError(
        (_) => false,
      );
      if (!mounted) return;
      setState(() {
        _granted = enabled;
        _success = enabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _granted = false;
        _success = false;
      });
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await _native.enableGrayscale().catchError((_) => false);
      if (!mounted) return;
      if (!ok) {
        // Permission not granted
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permission required'),
            content: SelectableText(
              'To enable grayscale this app needs WRITE_SECURE_SETTINGS. Run the following on your computer:\n\n$_adbCommand',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _adbCommand));
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          _granted = false;
          _success = false;
        });
      } else {
        scaffoldMessenger?.showSnackBar(
          const SnackBar(content: Text('Grayscale enabled')),
        );
        setState(() {
          _granted = true;
          _success = true;
        });
        // Optionally revert immediately for demo safety
        await Future.delayed(const Duration(milliseconds: 600));
        try {
          await _native.disableGrayscale();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to toggle grayscale: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ADB Grayscale',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This step is optional but recommended for the demo. Granting WRITE_SECURE_SETTINGS allows the app to toggle grayscale for demonstration.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 16),

          // Selectable ADB command with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _adbCommand,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    await Clipboard.setData(ClipboardData(text: _adbCommand));
                    if (!mounted) return;
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('ADB command copied')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
                onPressed: _testing || _success ? null : _test,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (_success
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Icon(Icons.play_arrow)),
                label: Text(_success ? 'Enabled' : 'Test'),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container()),
              // Next button always enabled; show warning icon if not granted
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
                onPressed: widget.onNext,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Next'),
                    const SizedBox(width: 8),
                    if (!_granted)
                      const Icon(Icons.warning, color: Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
