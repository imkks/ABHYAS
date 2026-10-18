import 'package:flutter/material.dart';
import '../../engine/progression/guru_anumati_workflow.dart';

import '../dev/teacher_console_mock_screen.dart';
import 'weaning_screen.dart';

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
        padding: EdgeInsets.all(24),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.deepPurple.shade900, Colors.indigo.shade900]),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.amber, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brahma Muhurta in 4h 30m', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Panchang: Ekadashi Tithi', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ]
                  )
                )
              ]
            )
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularStat('Tapas', '450', Colors.deepOrange),
              _buildCircularStat('Sopana', '2', Colors.blue),
              _buildCircularStat('CHT', '22s', Colors.teal),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.psychology),
            label: Text('Guidance Level (Weaning)'),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => WeaningScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 30),

          Text('Mudra & Bandha Seals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSeal('Gyan', true),
              _buildSeal('Chin', true),
              _buildSeal('Dhyana', true),
              _buildSeal('Nasika', false),
              _buildSeal('Jalandhara', false),
            ],
          ),

          SizedBox(height: 40),
          Text('Guru Anumati', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          SizedBox(height: 16),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isApproved ? Colors.green : Colors.transparent, width: 2)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Text('Sopana $nextLevel: Antar', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isApproved ? 'Approved for Practice' : (hasPendingRequest ? 'Awaiting Teacher Review' : 'Tap to Request Unlock')),
              trailing: isApproved
                ? Icon(Icons.check_circle, color: Colors.green, size: 32)
                : (hasPendingRequest ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)) : Icon(Icons.lock, color: Colors.grey, size: 32)),
              onTap: (!isApproved && !hasPendingRequest) ? () => _requestUnlock(nextLevel) : null,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildCircularStat(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 4),
            boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]
          ),
          child: Center(
            child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        SizedBox(height: 12),
        Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildSeal(String name, bool earned) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: earned ? Colors.green : Colors.transparent)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(earned ? Icons.stars : Icons.lock_outline, size: 16, color: earned ? Colors.green : Colors.grey),
          SizedBox(width: 8),
          Text(name, style: TextStyle(color: earned ? Colors.white : Colors.grey)),
        ],
      )
    );
  }
}
