import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'setup_pages/welcome_page.dart';
import 'setup_pages/set_default_page.dart';
import 'setup_pages/usage_access_page.dart';
import 'setup_pages/accessibility_page.dart';
import 'setup_pages/notification_access_page.dart';
import 'setup_pages/adb_grayscale_page.dart';
import 'setup_pages/contacts_page.dart';
import 'setup_pages/complete_page.dart';
import '../core/hive_service.dart';
import '../screens/terminal_home_screen.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _controller = PageController();
  final List<Widget> _pages = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      WelcomePage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      SetDefaultPage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      UsageAccessPage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      AccessibilityPage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      NotificationAccessPage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      AdbGrayscalePage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      ContactsPage(
        onNext: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
      CompletePage(
        onFinish: () async {
          await HiveService.setSetting('isSetupComplete', true);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TerminalHomeScreen()),
          );
        },
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on the first page, go back to previous page
        if (_currentPage > 0) {
          _controller.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false; // we've handled the pop
        }
        // On the first page, exit the app
        try {
          SystemNavigator.pop();
        } catch (_) {}
        return false;
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: PageView(
            controller: _controller,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            children: _pages,
          ),
        ),
      ),
    );
  }
}
