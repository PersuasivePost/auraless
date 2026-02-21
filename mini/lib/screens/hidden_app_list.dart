import 'package:flutter/material.dart';
import 'package:auraless/core/native_channel_service.dart';
import 'package:auraless/constants/colors.dart';

class HiddenAppList extends StatefulWidget {
  const HiddenAppList({super.key});

  @override
  State<HiddenAppList> createState() => _HiddenAppListState();
}

class _HiddenAppListState extends State<HiddenAppList> {
  final NativeChannelService _native = NativeChannelService();
  List<Map<String, dynamic>> _apps = [];
  final List<String> _favorites = []; // TODO: persist in Hive later
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    try {
      final apps = await _native.getInstalledApps();
      if (!mounted) return;
      apps.sort((a, b) {
        final an = (a['name'] ?? '').toString();
        final bn = (b['name'] ?? '').toString();
        return an.compareTo(bn);
      });
      setState(() {
        _apps = apps.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onAppTap(Map<String, dynamic> app) async {
    final pkg = app['packageName'] as String?;
    if (pkg == null) return;
    await _native.launchApp(pkg);
    // close list
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onLongPress(Map<String, dynamic> app) async {
    final name = (app['name'] ?? app['packageName'] ?? 'app').toString();
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fill,
      items: [
        PopupMenuItem(value: 'fav', child: Text('Add to favorites')),
        const PopupMenuItem(value: 'info', child: Text('App info')),
        const PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
      ],
    );

    switch (result) {
      case 'fav':
        setState(() {
          _favorites.add(name);
        });
        break;
      case 'info':
        // placeholder
        break;
      case 'uninstall':
        // placeholder
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Apps',
          style: TextStyle(color: primaryGreen, fontFamily: 'monospace'),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  if (_favorites.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'FAVORITES',
                          style: TextStyle(
                            color: primaryGreen,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _appRow(_favorites[index]),
                        childCount: _favorites.length,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'ALL APPS',
                        style: TextStyle(
                          color: dimGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _appRow(
                        _apps[index]['name'] ?? _apps[index]['packageName'],
                      ),
                      childCount: _apps.length,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _appRow(dynamic name) {
    final label = name?.toString() ?? 'unknown';
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: () {
          // find app by name
          final match = _apps.firstWhere(
            (a) => (a['name'] ?? a['packageName']) == name,
            orElse: () => {},
          );
          if (match.isNotEmpty) _onAppTap(match);
        },
        onLongPress: () {
          final match = _apps.firstWhere(
            (a) => (a['name'] ?? a['packageName']) == name,
            orElse: () => {},
          );
          if (match.isNotEmpty) _onLongPress(match);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(color: primaryGreen, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}
