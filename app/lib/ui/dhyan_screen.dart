import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

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
          SizedBox(height: 20),
          GestureDetector(
            onTap: _incrementMala,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${_malaCount}',
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Center(child: Text('Tap the circle to count and feel the bead.', style: TextStyle(color: Colors.grey))),

          SizedBox(height: 40),
          Text('Meditation Practices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.self_improvement),
            title: Text('Breath Awareness'),
            trailing: Icon(Icons.play_arrow),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Breath Awareness audio placeholder')));
            },
          ),
          ListTile(
            leading: Icon(Icons.bedtime),
            title: Text('Yoga Nidra (20 min)'),
            trailing: Icon(Icons.play_arrow),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yoga Nidra audio placeholder')));
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Trataka (Candle Flame)'),
            trailing: Icon(Icons.lock, color: Colors.red),
            subtitle: Text('Locked: Guru Anumati Required'),
          )
        ],
      ),
    );
  }
}
