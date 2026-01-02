import 'package:flutter/material.dart';

import '../groups/groups_page.dart';
import '../settings/settings_page.dart';
import '../../widgets/modern_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    GroupsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(
        selectedIndex: index,
        onTap: (i) => setState(() => index = i),
      ),
    );
  }
}

