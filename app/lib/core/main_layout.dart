import 'package:flutter/material.dart';
import '../engine/safety/safety_rules_engine.dart';
import '../features/today/today_screen.dart';
import '../features/practice/practice_list_screen.dart';
import '../features/dhyan/dhyan_screen.dart';
import '../features/me/progress_screen.dart';
import '../features/library/rituals_screen.dart';
import '../features/onboarding/health_screening_screen.dart';

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
      TodayScreen(),
      PracticeListScreen(safetyProfile: widget.safetyProfile),
      DhyanScreen(),
      RitualsScreen(),
      ProgressScreen(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: 'Aaj',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Abhyas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Dhyan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Rituals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Mera',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => HealthScreeningScreen(isUpdating: true)
          ));
        },
        tooltip: 'Update Health Profile',
        child: Icon(Icons.health_and_safety),
      ),
    );
  }
}
