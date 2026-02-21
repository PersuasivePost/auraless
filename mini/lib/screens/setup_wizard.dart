import 'package:flutter/material.dart';
import 'colors.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({Key? key}) : super(key: key);

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _controller = PageController();
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildPage('Welcome', 'Intro to mini and philosophy.'),
      _buildPage('Set Default', 'Make mini your default launcher.'),
      _buildPage('Usage Access', 'Optional: enable usage access for digests.'),
      _buildPage('Accessibility', 'Enable accessibility features if needed.'),
      _buildPage('Notification Access', 'Allow notification digest (opt-in).'),
      _buildPage('ADB Grayscale', 'Enable ADB grayscale demo (optional).'),
      _buildPage('Contacts', 'Optional: import contacts or shortcuts.'),
      _buildPage('Complete', 'Finish setup and go to terminal.'),
    ]);
  }

  Widget _buildPage(String title, String body) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 28,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: TextStyle(color: kOutputGreen, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 24),
          // placeholder controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
                onPressed: () {
                  final previous = _controller.page?.toInt() ?? 0;
                  if (previous > 0)
                    _controller.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                },
                child: const Text('Back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
                onPressed: () {
                  final next = _controller.page?.toInt() ?? 0;
                  if (next < 7)
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: PageView(controller: _controller, children: _pages),
      ),
    );
  }
}
