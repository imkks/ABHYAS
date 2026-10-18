import 'package:flutter/material.dart';
import '../progression/guru_anumati_workflow.dart';

import 'teacher_console_mock_screen.dart';

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final GuruAnumatiWorkflow _workflow = GuruAnumatiWorkflow();

  void _requestUnlock(int level) {
    setState(() {
      _workflow.requestUnlock(level);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unlock request sent to teacher for Level $level'))
    );
  }

  void _simulateTeacherAction(int level, bool approve) {
    setState(() {
      _workflow.simulateTeacherApproval(level, approve, approve ? 'Good progress.' : 'Needs more practice.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final nextLevel = 3;
    final hasPendingRequest = _workflow.requests.any((r) => r.requestedLevel == nextLevel && r.status == UnlockStatus.pending);
    final isApproved = _workflow.isLevelApproved(nextLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Progress'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => TeacherConsoleMockScreen(workflow: _workflow),
              ));
            },
            tooltip: 'Teacher Console',
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildStatCard('Current Sopana', '2 (Abhyasa)', Icons.stairs),
          _buildStatCard('Tapas Points', '450', Icons.local_fire_department),
          _buildStatCard('Vishrama Days Left', '1', Icons.weekend),
          _buildStatCard('Comfort Hold Time (CHT)', '22s', Icons.timer),

          SizedBox(height: 30),
          Text('Mudra & Bandha Seals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSeal('Gyan', true),
              _buildSeal('Chin', true),
              _buildSeal('Dhyana', true),
              _buildSeal('Nasika', false),
              _buildSeal('Jalandhara', false),
            ],
          ),

          SizedBox(height: 30),
          Text('Guru Anumati (Teacher Unlocks)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              title: Text('Sopana $nextLevel: Antar'),
              subtitle: Text(isApproved ? 'Approved!' : (hasPendingRequest ? 'Awaiting Teacher Review' : 'Locked by Teacher')),
              trailing: isApproved
                ? Icon(Icons.check_circle, color: Colors.green)
                : (hasPendingRequest ? Icon(Icons.hourglass_empty, color: Colors.orange) : Icon(Icons.lock, color: Colors.red)),
              onTap: (!isApproved && !hasPendingRequest) ? () => _requestUnlock(nextLevel) : null,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.orange),
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSeal(String name, bool earned) {
    return Chip(
      avatar: Icon(
        earned ? Icons.check_circle : Icons.lock,
        color: earned ? Colors.green : Colors.grey
      ),
      label: Text(name),
      backgroundColor: earned ? Colors.green.shade100 : Colors.grey.shade200,
    );
  }
}
