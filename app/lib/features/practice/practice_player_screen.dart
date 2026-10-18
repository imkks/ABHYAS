import 'package:flutter/material.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../engine/player/player_engine.dart';

import 'post_session_checkin_screen.dart';

class PracticePlayerScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;
  final String practiceName;
  final String practiceId;
  final int weaningStage; // 1 to 5

  const PracticePlayerScreen({
    Key? key,
    required this.safetyProfile,
    required this.practiceName,
    required this.practiceId,
    this.weaningStage = 1,
  }) : super(key: key);

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
        _engine.resumeTimer(_onTick);
        if (widget.weaningStage < 4) {
           // Audio cue placeholder
           print('Audio Cue: Phase Started');
        }
      } else {
        _engine.pauseTimer();
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

  void _finishPractice() {
    _engine.stopTimer();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PostSessionCheckinScreen(safetyProfile: widget.safetyProfile),
      ),
    );
  }

  @override
  void dispose() {
    _engine.stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showVisualPacer = widget.weaningStage < 3;
    bool showCounts = widget.weaningStage < 3;

    return Scaffold(
      appBar: AppBar(title: Text(widget.practiceName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.weaningStage > 1)
               Padding(
                 padding: EdgeInsets.all(8.0),
                 child: Text('Weaning Stage ${widget.weaningStage}: Guidance reduced.', style: TextStyle(color: Colors.orange)),
               ),
            if (widget.practiceId == 'kapalbhati' && showVisualPacer)
               Text('Strokes Pacer Active (1 per sec)', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),

            if (showVisualPacer)
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: _currentPhase == PracticePhase.puraka ? 200 : 100,
                height: _currentPhase == PracticePhase.puraka ? 200 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.3),
                  border: Border.all(color: Colors.blue, width: 2)
                ),
                child: Center(
                  child: Text(
                    _currentPhase.name.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            SizedBox(height: 30),
            if (showCounts)
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
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _finishPractice,
              child: Text('Finish Practice'),
            ),
          ],
        ),
      ),
    );
  }
}
