import 'package:flutter/material.dart';
import '../safety/safety_rules_engine.dart';
import 'practice_list_screen.dart';
import 'dhyan_screen.dart';
import 'progress_screen.dart';
import 'rituals_screen.dart';
import 'health_screening_screen.dart';

class MainLayout extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const MainLayout({Key? key, required this.safetyProfile}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PracticeListScreen(safetyProfile: widget.safetyProfile),
      DhyanScreen(),
      ProgressScreen(),
      RitualsScreen(),
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
            icon: Icon(Icons.self_improvement),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Dhyan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Rituals',
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
        child: Icon(Icons.health_and_safety),
        tooltip: 'Update Health Profile',
      ),
    );
  }
}
