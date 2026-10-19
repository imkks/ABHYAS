import 'package:flutter/material.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../core/main_layout.dart';
import '../../data/user_repository.dart';

class HealthScreeningScreen extends StatefulWidget {
  final bool isUpdating;

  const HealthScreeningScreen({Key? key, this.isUpdating = false}) : super(key: key);

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
  bool _emptyStomachConfirmed = false;

  void _proceed() async {
    final profile = SafetyProfile(
      pregnancy: _pregnancy,
      hypertension: _hypertension,
      heartCondition: _heartCondition,
      epilepsy: _epilepsy,
      glaucoma: _glaucoma,
      hernia: _hernia,
      recentSurgery: _recentSurgery,
      menstruation: _menstruation,
      emptyStomachConfirmed: _emptyStomachConfirmed,
    );

    final userRepo = UserRepository();
    await userRepo.saveProfile(profile);

    if (!mounted) return;

    if (widget.isUpdating) {
       // Since Dashboard is stateless, we push replacement to force rebuild with new state
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => MainLayout(safetyProfile: profile),
         ),
       );
    } else {
       Navigator.pushReplacement(
         context,
         MaterialPageRoute(
           builder: (context) => MainLayout(safetyProfile: profile),
         ),
       );
    }
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
          CheckboxListTile(
            title: Text('Empty Stomach Confirmed'),
            subtitle: Text('Required for Uddiyana & Maha Bandha'),
            value: _emptyStomachConfirmed,
            onChanged: (val) => setState(() => _emptyStomachConfirmed = val!),
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
