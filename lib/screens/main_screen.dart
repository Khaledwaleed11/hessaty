import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'payments_screen.dart';
import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const MainScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  void changePage(int index) {
    if (index == currentIndex) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final pages = [
      const HomeScreen(),
      const ScheduleScreen(),
      const StudentsScreen(),
      const PaymentsScreen(),
      SettingsScreen(
        onThemeToggle: widget.onThemeToggle,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: changePage,
        height: 72,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.primary.withValues(
          alpha: 0.12,
        ),
        labelBehavior:
        NavigationDestinationLabelBehavior.alwaysShow,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),

          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'الجدول',
          ),

          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'الطلاب',
          ),

          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'المصاريف',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}