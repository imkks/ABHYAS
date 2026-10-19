import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/session_repository.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import 'yoga_nidra_screen.dart';

class DhyanScreen extends StatefulWidget {
  @override
  _DhyanScreenState createState() => _DhyanScreenState();
}

class _DhyanScreenState extends State<DhyanScreen> {
  int _malaCount = 0;
  static const String _malaKey = 'daily_mala_count';

  @override
  void initState() {
    super.initState();
    _loadMalaCount();
  }

  Future<void> _loadMalaCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _malaCount = prefs.getInt(_malaKey) ?? 0;
      });
    }
  }

  Future<void> _saveMalaCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_malaKey, count);
  }

  void _incrementMala() async {
    final newCount = _malaCount + 1;
    setState(() {
      _malaCount = newCount;
    });
    await _saveMalaCount(_malaCount);

    if (_malaCount >= 108) {
      await Haptics.vibrate(HapticsType.heavy);

      // Log completed Mala round to session history
      final sessionRepo = SessionRepository();
      await sessionRepo.logSession(SessionRecord(
        practiceName: 'Japa Mala (108 beads)',
        level: 1,
        durationSeconds: 324,
        timestamp: DateTime.now(),
        checkinRating: 'calm',
      ));

      _showMeruDialog();
      setState(() {
        _malaCount = 0;
      });
      await _saveMalaCount(0);
    } else {
      await Haptics.vibrate(HapticsType.light);
    }
  }

  void _showMeruDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Meru Reached'),
        content: Text('You have completed 108 beads. Turn the mala and begin again or end practice.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tratakaUnlocked = GuruAnumatiWorkflow().isLevelApproved(4);

    return Scaffold(
      appBar: AppBar(title: Text('Dhyan & Mala')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Digital Mala (108)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Card(
             elevation: 4,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             child: Padding(
               padding: const EdgeInsets.all(24.0),
               child: Column(
                 children: [
                   GestureDetector(
                     onTap: _incrementMala,
                     child: Container(
                       height: 200,
                       decoration: BoxDecoration(
                         color: Colors.orange.shade100,
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.orange, width: 4),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.orange.withOpacity(0.3),
                             blurRadius: 10,
                             spreadRadius: 2,
                           )
                         ],
                       ),
                       child: Center(
                         child: Text(
                           '$_malaCount',
                           style: TextStyle(
                             fontSize: 64,
                             fontWeight: FontWeight.bold,
                             color: Colors.orange.shade800,
                           ),
                         ),
                       ),
                     ),
                   ),
                   SizedBox(height: 20),
                   Text('Tap the circle to advance the bead.', style: TextStyle(color: Colors.grey.shade600)),
                   SizedBox(height: 10),
                   LinearProgressIndicator(
                     value: _malaCount / 108.0,
                     backgroundColor: Colors.orange.shade50,
                     color: Colors.orange,
                   )
                 ],
               ),
             ),
          ),

          SizedBox(height: 30),
          Text('Meditation Practices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildMeditationCard('Breath Awareness', 'Witness your natural breath.', Icons.self_improvement, Colors.blue, false, routeTo: null),
          _buildMeditationCard('Yoga Nidra (20 min)', 'Deep conscious relaxation.', Icons.bedtime, Colors.indigo, false, routeTo: YogaNidraScreen(durationMinutes: 20)),
          _buildMeditationCard('Trataka (Candle Flame)', tratakaUnlocked ? 'Cleared by teacher.' : 'Requires Guru Anumati (Level 4).', Icons.visibility, Colors.purple, !tratakaUnlocked, routeTo: null),
        ],
      ),
    );
  }

  Widget _buildMeditationCard(String title, String subtitle, IconData icon, Color color, bool locked, {Widget? routeTo}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(locked ? Icons.lock : Icons.play_arrow, color: locked ? Colors.red : Colors.green),
        onTap: locked ? null : () {
          if (routeTo != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => routeTo));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting $title...')));
          }
        },
      ),
    );
  }
}
