import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'level_detail_screen.dart';
import '../../engine/progression/guru_anumati_workflow.dart';

class PathScreen extends StatelessWidget {
  const PathScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Path')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSopanaStep(context, 7, 'Dhyana', 'guru_only', false),
          _buildSopanaStep(context, 6, 'Bahya', 'teacher', false),
          _buildSopanaStep(context, 5, 'Kumbhaka', 'teacher', false),
          _buildSopanaStep(context, 4, 'Shakti', 'teacher', false),
          _buildSopanaStep(context, 3, 'Antar', 'teacher', false, isCurrent: true),
          _buildSopanaStep(context, 2, 'Abhyasa', 'streak', true),
          _buildSopanaStep(context, 1, 'Prarambha', 'self', true),
        ],
      ),
    );
  }

  Widget _buildSopanaStep(BuildContext context, int levelId, String name, String gate, bool isComplete, {bool isCurrent = false}) {
    IconData icon;
    Color color;
    String statusText;

    if (isComplete) {
      icon = Icons.check_circle;
      color = AbhyasTheme.leaf;
      statusText = 'Complete';
    } else if (isCurrent) {
      icon = Icons.radio_button_checked;
      color = AbhyasTheme.saffron;
      statusText = 'Current';
    } else {
      icon = Icons.lock;
      color = Colors.grey;
      statusText = gate == 'teacher' ? 'Requires Teacher Approval' : 'Requires Guru Approval';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text('Level $levelId: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(statusText),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => LevelDetailScreen(levelId: levelId, name: name, gate: gate, isComplete: isComplete, isCurrent: isCurrent)
          ));
        },
      ),
    );
  }
}
