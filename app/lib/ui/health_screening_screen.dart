import 'package:flutter/material.dart';
import '../safety/safety_rules_engine.dart';
import 'practice_player_screen.dart';

class HealthScreeningScreen extends StatefulWidget {
  @override
  _HealthScreeningScreenState createState() => _HealthScreeningScreenState();
}

class _HealthScreeningScreenState extends State<HealthScreeningScreen> {
  bool _pregnancy = false;
  bool _hypertension = false;
  bool _heartCondition = false;
  bool _epilepsy = false;
  bool _glaucoma = false;
  bool _hernia = false;
  bool _recentSurgery = false;
  bool _menstruation = false;

  void _proceed() {
    final profile = SafetyProfile(
      pregnancy: _pregnancy,
      hypertension: _hypertension,
      heartCondition: _heartCondition,
      epilepsy: _epilepsy,
      glaucoma: _glaucoma,
      hernia: _hernia,
      recentSurgery: _recentSurgery,
      menstruation: _menstruation,
      emptyStomachConfirmed: true, // Auto-confirm for this simple Phase 1 E2E
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PracticePlayerScreen(safetyProfile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Health Screening')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Please select any conditions that apply to you:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          CheckboxListTile(
            title: Text('Pregnancy'),
            value: _pregnancy,
            onChanged: (val) => setState(() => _pregnancy = val!),
          ),
          CheckboxListTile(
            title: Text('Hypertension'),
            value: _hypertension,
            onChanged: (val) => setState(() => _hypertension = val!),
          ),
          CheckboxListTile(
            title: Text('Heart Condition'),
            value: _heartCondition,
            onChanged: (val) => setState(() => _heartCondition = val!),
          ),
          CheckboxListTile(
            title: Text('Epilepsy'),
            value: _epilepsy,
            onChanged: (val) => setState(() => _epilepsy = val!),
          ),
          CheckboxListTile(
            title: Text('Glaucoma'),
            value: _glaucoma,
            onChanged: (val) => setState(() => _glaucoma = val!),
          ),
          CheckboxListTile(
            title: Text('Hernia'),
            value: _hernia,
            onChanged: (val) => setState(() => _hernia = val!),
          ),
          CheckboxListTile(
            title: Text('Recent Surgery'),
            value: _recentSurgery,
            onChanged: (val) => setState(() => _recentSurgery = val!),
          ),
          CheckboxListTile(
            title: Text('Menstruation'),
            value: _menstruation,
            onChanged: (val) => setState(() => _menstruation = val!),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _proceed,
            child: Text('Proceed to Practice'),
          ),
        ],
      ),
    );
  }
}
