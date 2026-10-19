import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../data/user_repository.dart';
import 'dart:async';

class SelfCheckPracticeScreen extends StatefulWidget {
  @override
  _SelfCheckPracticeScreenState createState() => _SelfCheckPracticeScreenState();
}

class _SelfCheckPracticeScreenState extends State<SelfCheckPracticeScreen> {
  bool _isTiming = false;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

  List<int> _recordedHolds = [];
  final int _targetHoldSeconds = 12; // Example from config

  void _toggleTimer() {
    setState(() {
      if (_isTiming) {
        _stopwatch.stop();
        _uiTimer?.cancel();
        _recordedHolds.add(_stopwatch.elapsed.inSeconds);
        _stopwatch.reset();
        _isTiming = false;

        // Mock finish after 3 rounds
        if (_recordedHolds.length >= 3) {
          _showResults();
        }
      } else {
        _isTiming = true;
        _stopwatch.start();
        _uiTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
          setState(() {}); // Minimal UI update just for visual feedback of active state (but explicit numbers are hidden as per Stage 5 specs)
        });
      }
    });
  }

  void _showResults() async {
    // Calculate simple steadiness
    double avg = _recordedHolds.reduce((a, b) => a + b) / _recordedHolds.length;
    double diffFromTarget = (avg - _targetHoldSeconds).abs();

    String feedback = 'Steadiness developing.';
    if (diffFromTarget < 2) {
      feedback = 'Excellent internal rhythm!';
    } else if (avg < _targetHoldSeconds) {
      feedback = 'You are releasing early. Ensure you are comfortable.';
    }

    final sessionRepo = SessionRepository();
    await sessionRepo.logSession(SessionRecord(
      practiceName: 'Self-Check Kumbhaka',
      level: 5,
      durationSeconds: _recordedHolds.reduce((a, b) => a + b),
      timestamp: DateTime.now(),
      checkinRating: diffFromTarget < 2 ? 'calm' : 'neutral',
      holdDurations: _recordedHolds.map((h) => h.toDouble()).toList(),
    ));

    final userRepo = UserRepository();
    await userRepo.saveChtBenchmark(avg);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AbhyasTheme.darkSurface,
        title: Text('Self-Check Results', style: TextStyle(color: AbhyasTheme.saffron)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: $_targetHoldSeconds seconds', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Text('Your recorded holds: ${_recordedHolds.join(", ")} s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 20),
            Text(feedback, style: TextStyle(color: AbhyasTheme.leaf, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit screen
            },
            child: Text('End Session')
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Self-Check Practice'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stage 5: Independent',
              style: TextStyle(color: AbhyasTheme.saffron, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Count your breath internally.\nTap to start and stop your Kumbhaka hold.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 16),
            ),
            SizedBox(height: 60),

            GestureDetector(
              onTap: _toggleTimer,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTiming ? AbhyasTheme.hold.withOpacity(0.3) : AbhyasTheme.darkSurfaceAlt,
                  border: Border.all(color: _isTiming ? AbhyasTheme.hold : AbhyasTheme.line, width: 4),
                  boxShadow: _isTiming ? [BoxShadow(color: AbhyasTheme.hold.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)] : [],
                ),
                child: Center(
                  child: Text(
                    _isTiming ? 'HOLDING' : 'TAP TO START HOLD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isTiming ? Colors.white : AbhyasTheme.darkInkSoft
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 60),
            Text('Round ${_recordedHolds.length + 1} of 3', style: TextStyle(color: Colors.white54, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
