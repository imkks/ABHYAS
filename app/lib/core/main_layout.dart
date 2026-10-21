import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../engine/safety/safety_rules_engine.dart';
import '../features/today/today_screen.dart';
import '../features/practice/practice_list_screen.dart';
import '../features/dhyan/dhyan_screen.dart';
import '../features/me/progress_screen.dart';
import '../features/library/rituals_screen.dart';

class MainLayout extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const MainLayout({super.key, required this.safetyProfile});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const TodayScreen(),
      PracticeListScreen(safetyProfile: widget.safetyProfile),
      const DhyanScreen(),
      const RitualsScreen(),
      const ProgressScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF191824),
        selectedItemColor: AbhyasTheme.saffron,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny),
            label: 'Sadhana',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement_outlined),
            activeIcon: Icon(Icons.self_improvement),
            label: 'Abhyas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Dhyan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Vidyapeeth',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mera',
          ),
        ],
      ),
    );
  }
}
