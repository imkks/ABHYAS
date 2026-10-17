import 'package:flutter/material.dart';
import '../safety/safety_rules_engine.dart';
import '../player/player_engine.dart';

class PracticePlayerScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const PracticePlayerScreen({Key? key, required this.safetyProfile}) : super(key: key);

  @override
  _PracticePlayerScreenState createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  late PlayerEngine _engine;
  PracticePhase _currentPhase = PracticePhase.puraka;
  int _secondsElapsed = 0;
  bool _isPlaying = false;

  // Example Config for Level 1 ratio (1:0:1:0)
  final List<int> ratio = [4, 0, 4, 0];

  @override
  void initState() {
    super.initState();
    _engine = PlayerEngine(
      holdCapFractionOfCht: 0.6,
      levelCapSeconds: 30,
      userChtSeconds: 20, // default from onboarding usually
    );
  }

  void _onTick(int seconds) {
    setState(() {
      _secondsElapsed = seconds;

      int currentPhaseTarget = 0;
      switch (_currentPhase) {
        case PracticePhase.puraka:
          currentPhaseTarget = ratio[0];
          break;
        case PracticePhase.antarKumbhaka:
          currentPhaseTarget = _engine.scheduleHold(ratio[1]);
          break;
        case PracticePhase.rechaka:
          currentPhaseTarget = ratio[2];
          break;
        case PracticePhase.bahyaKumbhaka:
          currentPhaseTarget = _engine.scheduleHold(ratio[3]);
          break;
        case PracticePhase.naturalBreath:
          currentPhaseTarget = 4; // Arbitrary for natural breath UI
          break;
      }

      if (_secondsElapsed >= currentPhaseTarget) {
         _secondsElapsed = 0;
         _engine.stopTimer();
         _currentPhase = _engine.getNextPhase(_currentPhase);
         if (_isPlaying) {
             _engine.startTimer(_onTick);
         }
      }
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _engine.startTimer(_onTick);
      } else {
        _engine.stopTimer();
      }
    });
  }

  void _returnToNaturalBreath() {
    setState(() {
      _isPlaying = false;
      _engine.stopTimer();
      _secondsElapsed = 0;
      _currentPhase = _engine.returnToNaturalBreath();
    });
  }

  @override
  void dispose() {
    _engine.stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Practice Player (Level 1)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Phase: ${_currentPhase.name}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '${_secondsElapsed} s',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _togglePlay,
                  child: Text(_isPlaying ? 'Pause' : 'Start'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _returnToNaturalBreath,
                  child: Text('Return to Natural Breath', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
