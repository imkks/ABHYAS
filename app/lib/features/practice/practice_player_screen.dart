import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptic_service.dart';
import '../../data/user_repository.dart';
import '../../engine/player/player_engine.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'post_session_checkin_screen.dart';

class PracticePlayerScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;
  final String practiceName;
  final String practiceId;
  final int weaningStage; // 1 to 5
  final List<int>? ratio; // [puraka, antar, rechaka, bahya]
  final int rounds;

  const PracticePlayerScreen({
    super.key,
    required this.safetyProfile,
    required this.practiceName,
    required this.practiceId,
    this.weaningStage = 1,
    this.ratio,
    this.rounds = 5,
  });

  @override
  State<PracticePlayerScreen> createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  late PlayerEngine _engine;
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();

  PracticePhase _currentPhase = PracticePhase.puraka;
  int _secondsElapsed = 0;
  int _totalSecondsElapsed = 0;
  int _currentRound = 1;
  bool _isPlaying = false;

  late List<int> _activeRatio;

  @override
  void initState() {
    super.initState();
    _activeRatio = widget.ratio ?? [4, 0, 4, 0];

    _engine = PlayerEngine(
      holdCapFractionOfCht: 0.6,
      levelCapSeconds: 30,
      userChtSeconds: 20,
    );

    _initCht();
  }

  Future<void> _initCht() async {
    final cht = await UserRepository().loadChtBenchmark();
    if (cht != null && mounted) {
      _engine = PlayerEngine(
        holdCapFractionOfCht: 0.6,
        levelCapSeconds: 30,
        userChtSeconds: cht.toInt(),
      );
    }
  }

  void _onTick(int seconds) {
    setState(() {
      _secondsElapsed = seconds;
      _totalSecondsElapsed++;

      // Matra pulse on each tick
      _hapticService.pulseForMatra(widget.weaningStage);
      _audioService.playTick();

      int currentPhaseTarget = 0;
      switch (_currentPhase) {
        case PracticePhase.puraka:
          currentPhaseTarget = _activeRatio[0] > 0 ? _activeRatio[0] : 4;
          break;
        case PracticePhase.antarKumbhaka:
          currentPhaseTarget = _engine.scheduleHold(_activeRatio[1]);
          break;
        case PracticePhase.rechaka:
          currentPhaseTarget = _activeRatio[2] > 0 ? _activeRatio[2] : 4;
          break;
        case PracticePhase.bahyaKumbhaka:
          currentPhaseTarget = _engine.scheduleHold(_activeRatio[3]);
          break;
        case PracticePhase.naturalBreath:
          currentPhaseTarget = 4;
          break;
      }

      if (_secondsElapsed >= currentPhaseTarget) {
        _secondsElapsed = 0;
        _engine.stopTimer();

        final nextPhase = _engine.getNextPhase(_currentPhase);

        // Check if round completed
        final isRoundEnd = _currentPhase == PracticePhase.bahyaKumbhaka ||
            (_activeRatio[3] == 0 && _currentPhase == PracticePhase.rechaka);

        if (isRoundEnd) {
          _hapticService.roundCompletePulse(widget.weaningStage);
          if (_currentRound >= widget.rounds) {
            _finishPractice();
            return;
          } else {
            _currentRound++;
          }
        }

        _currentPhase = nextPhase;

        // Skip hold phases if ratio specifies 0
        if (_currentPhase == PracticePhase.antarKumbhaka && _activeRatio[1] == 0) {
          _currentPhase = PracticePhase.rechaka;
        } else if (_currentPhase == PracticePhase.bahyaKumbhaka && _activeRatio[3] == 0) {
          _currentPhase = PracticePhase.puraka;
        }

        // Phase transition cues
        _audioService.playBell(BellType.transition);
        _hapticService.phaseTransitionPulse(widget.weaningStage);

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
        _audioService.playBell(BellType.start);
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
    _audioService.playBell(BellType.end);
    _audioService.stopAll();
    _hapticService.completionPulse();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PostSessionCheckinScreen(
          safetyProfile: widget.safetyProfile,
          practiceName: widget.practiceName,
          durationSeconds: _totalSecondsElapsed > 0 ? _totalSecondsElapsed : 300,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine.stopTimer();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showVisualPacer = widget.weaningStage < 3;
    bool showCounts = widget.weaningStage < 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.practiceName),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            tooltip: 'Finish Session',
            onPressed: _finishPractice,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Round $_currentRound of ${widget.rounds}',
              style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Ratio: ${_activeRatio.join(" : ")}',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 20),

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
                width: _currentPhase == PracticePhase.puraka
                    ? 220
                    : (_currentPhase == PracticePhase.rechaka ? 120 : 170),
                height: _currentPhase == PracticePhase.puraka
                    ? 220
                    : (_currentPhase == PracticePhase.rechaka ? 120 : 170),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPhaseColor(_currentPhase).withValues(alpha: 0.3),
                  border: Border.all(color: _getPhaseColor(_currentPhase), width: 3),
                ),
                child: Center(
                  child: Text(
                    _currentPhase.name.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

            SizedBox(height: 30),
            if (showCounts)
              Text(
                '$_secondsElapsed s',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
              ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _togglePlay,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(_isPlaying ? 'Pause' : 'Start'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _returnToNaturalBreath,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Natural Breath'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor(PracticePhase phase) {
    switch (phase) {
      case PracticePhase.puraka:
        return Colors.blue;
      case PracticePhase.antarKumbhaka:
        return Colors.purpleAccent;
      case PracticePhase.rechaka:
        return Colors.teal;
      case PracticePhase.bahyaKumbhaka:
        return Colors.deepOrange;
      case PracticePhase.naturalBreath:
        return Colors.green;
    }
  }
}
