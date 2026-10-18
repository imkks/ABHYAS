import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'yoga_nidra_screen.dart';

class DhyanScreen extends StatefulWidget {
  @override
  _DhyanScreenState createState() => _DhyanScreenState();
}

class _DhyanScreenState extends State<DhyanScreen> {
  int _malaCount = 0;

  void _incrementMala() async {
    setState(() {
      _malaCount++;
    });

    if (_malaCount == 108) {
      await Haptics.vibrate(HapticsType.heavy);
      _showMeruDialog();
      _malaCount = 0; // Reset for next round
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
                             spreadRadius: 2
                           )
                         ]
                       ),
                       child: Center(
                         child: Text(
                           '${_malaCount}',
                           style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
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
                 ]
               )
             )
          ),

          SizedBox(height: 30),
          Text('Meditation Practices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildMeditationCard('Breath Awareness', 'Witness your natural breath.', Icons.self_improvement, Colors.blue, false, routeTo: null),
          _buildMeditationCard('Yoga Nidra (20 min)', 'Deep conscious relaxation.', Icons.bedtime, Colors.indigo, false, routeTo: YogaNidraScreen(durationMinutes: 20)),
          _buildMeditationCard('Trataka (Candle Flame)', 'Requires Guru Anumati.', Icons.visibility, Colors.grey, true, routeTo: null),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing ${title}')));
          }
        },
      ),
    );
  }
}
