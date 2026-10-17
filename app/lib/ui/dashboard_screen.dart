import 'package:flutter/material.dart';
import 'practice_list_screen.dart';
import 'dhyan_screen.dart';
import 'progress_screen.dart';
import 'rituals_screen.dart';
import 'health_screening_screen.dart';
import '../safety/safety_rules_engine.dart';

class DashboardScreen extends StatelessWidget {
  final SafetyProfile safetyProfile;

  DashboardScreen({required this.safetyProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Abhyas Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, 'Daily Practice', Icons.self_improvement, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => PracticeListScreen(safetyProfile: safetyProfile)
            ));
          }),
          _buildCard(context, 'Dhyan & Mala', Icons.spa, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => DhyanScreen()
            ));
          }),
          _buildCard(context, 'My Progress', Icons.trending_up, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => ProgressScreen()
            ));
          }),
          _buildCard(context, 'Vedic Rituals', Icons.local_fire_department, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => RitualsScreen()
            ));
          }),
          _buildCard(context, 'Update Health', Icons.health_and_safety, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => HealthScreeningScreen(isUpdating: true)
            ));
          }),
          _buildCard(context, 'Settings', Icons.settings, () {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings Coming Soon')));
          }),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
