import 'package:flutter/material.dart';
import '../safety/safety_rules_engine.dart';
import 'practice_player_screen.dart';

class PracticeListScreen extends StatelessWidget {
  final SafetyProfile safetyProfile;

  PracticeListScreen({required this.safetyProfile});

  // Dummy list based on Level 1 and 2 from requirements
  final List<Map<String, dynamic>> practices = [
    {'id': 'breath_awareness', 'name': 'Breath Awareness (Level 1)'},
    {'id': 'om_chant', 'name': 'Om Chanting (Level 1)'},
    {'id': 'bhramari', 'name': 'Bhramari (Level 1)'},
    {'id': 'nadi_shodhana', 'name': 'Nadi Shodhana Basic (Level 1)'},
    {'id': 'kapalbhati', 'name': 'Kapalbhati (Level 2)'},
    {'id': 'ujjayi', 'name': 'Ujjayi (Level 2)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sopanas (Levels 1-2)')),
      body: ListView.builder(
        itemCount: practices.length,
        itemBuilder: (context, index) {
          final practice = practices[index];
          final bool allowed = SafetyRulesEngine.isPracticeAllowed(
            practice['id'],
            safetyProfile,
            false // No teacher clearance in offline basic test
          );

          return ListTile(
            title: Text(practice['name']),
            subtitle: allowed ? null : Text('Locked: Consult doctor/teacher', style: TextStyle(color: Colors.red)),
            trailing: allowed ? Icon(Icons.play_arrow) : Icon(Icons.lock, color: Colors.red),
            onTap: allowed ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: safetyProfile,
                    practiceName: practice['name'],
                    practiceId: practice['id'],
                  ),
                ),
              );
            } : null,
          );
        },
      ),
    );
  }
}
