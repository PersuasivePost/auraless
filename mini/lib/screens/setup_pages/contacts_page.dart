import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../colors.dart';

class ContactsPage extends StatefulWidget {
  final VoidCallback onNext;
  const ContactsPage({super.key, required this.onNext});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _granted = false;

  Future<void> _check() async {
    final status = await Permission.contacts.status;
    if (!mounted) return;
    setState(() => _granted = status.isGranted);
  }

  Future<void> _request() async {
    final status = await Permission.contacts.request();
    if (!mounted) return;
    setState(() => _granted = status.isGranted);
  }

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Contacts',
            style: TextStyle(
              color: kPrimaryGreen,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Allow contacts permission to enable call shortcuts.',
            style: TextStyle(color: kOutputGreen),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen),
            onPressed: _request,
            child: const Text('Grant Contacts Permission'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDimGreen),
            onPressed: _granted ? widget.onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
