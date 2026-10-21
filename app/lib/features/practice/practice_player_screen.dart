import 'dart:async';
import 'package:flutter/material.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../engine/player/player_engine.dart';
import '../../engine/player/audio_guidance_engine.dart';
import '../../core/audio/practice_audio_service.dart';
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
  late AudioGuidanceEngine _audioEngine;
  final PracticeAudioService _audioService = PracticeAudioService();

  PracticePhase _currentPhase = PracticePhase.puraka;
  int _secondsElapsed = 0;
  bool _isPlaying = false;
  bool _isSettling = false;
  bool _isIntegrating = false;
  Timer? _bufferTimer;

  // Level 1 ratio (1:0:1:0)
  final List<int> ratio = [4, 0, 4, 0];

  @override
  void initState() {
    super.initState();
    _engine = PlayerEngine(
      holdCapFractionOfCht: 0.6,
      levelCapSeconds: 30,
      userChtSeconds: 20,
    );

    _audioEngine = AudioGuidanceEngine(
      weaningStage: widget.weaningStage,
      settlingDurationSeconds: 10,
      integrationDurationSeconds: 60,
    );
    _audioService.initAudio();
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
          currentPhaseTarget = 4;
          break;
      }

      if (_secondsElapsed >= currentPhaseTarget) {
        _secondsElapsed = 0;
        _engine.stopTimer();
        _currentPhase = _engine.getNextPhase(_currentPhase);

        // Play phase audio transition cue (minimal speech + tonal earcon)
        final cue = _audioEngine.getCueForPhaseTransition(
          phase: _currentPhase,
          cycleNumber: _engine.currentCycle,
        );
        _audioService.dispatchCue(cue);

        if (_isPlaying) {
          _engine.startTimer(_onTick);
        }
      }
    });
  }

  /// Initiates hands-free settling buffer so user can put phone down and close eyes
  void _startWithSettlingBuffer() {
    setState(() {
      _isSettling = true;
      _isPlaying = false;
    });

    final startCue = _audioEngine.startSettlingBuffer();
    _audioService.dispatchCue(startCue);

    _bufferTimer?.cancel();
    _bufferTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        final tickCue = _audioEngine.tickSettlingBuffer();
        if (tickCue != null) {
          _audioService.dispatchCue(tickCue);
        }

        if (!_audioEngine.isSettling) {
          timer.cancel();
          _isSettling = false;
          _beginActivePractice();
        }
      });
    });
  }

  void _skipSettling() {
    _bufferTimer?.cancel();
    _audioService.stopAll();
    setState(() {
      _isSettling = false;
    });
    _beginActivePractice();
  }

  void _beginActivePractice() {
    setState(() {
      _isPlaying = true;
      _secondsElapsed = 0;
      _currentPhase = PracticePhase.puraka;
    });

    final cue = _audioEngine.getCueForPhaseTransition(
      phase: _currentPhase,
      cycleNumber: _engine.currentCycle,
    );
    _audioService.dispatchCue(cue);

    _engine.startTimer(_onTick);
  }

  void _togglePlay() {
    if (_isSettling) {
      _skipSettling();
      return;
    }

    if (_isIntegrating) {
      _finishPracticeNow();
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _engine.resumeTimer(_onTick);
        final cue = _audioEngine.getCueForPhaseTransition(
          phase: _currentPhase,
          cycleNumber: _engine.currentCycle,
        );
        _audioService.dispatchCue(cue);
      } else {
        _engine.pauseTimer();
      }
    });
  }

  /// Emergency Exit: AC-9 Immediate Return to Natural Breath
  void _returnToNaturalBreath() {
    _bufferTimer?.cancel();
    _audioService.stopAll();
    setState(() {
      _isPlaying = false;
      _isSettling = false;
      _engine.stopTimer();
      _secondsElapsed = 0;
      _currentPhase = _engine.returnToNaturalBreath();
    });

    final groundingCue = _audioEngine.getEmergencyGroundingCue();
    _audioService.dispatchCue(groundingCue);
  }

  /// Starts post-session integration buffer before navigating to check-in
  void _startIntegrationBuffer() {
    _engine.stopTimer();
    setState(() {
      _isPlaying = false;
      _isIntegrating = true;
    });

    final startCue = _audioEngine.startIntegrationBuffer();
    _audioService.dispatchCue(startCue);

    _bufferTimer?.cancel();
    _bufferTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        final tickCue = _audioEngine.tickIntegrationBuffer();
        if (tickCue != null) {
          _audioService.dispatchCue(tickCue);
        }

        if (!_audioEngine.isIntegrating) {
          timer.cancel();
          _finishPracticeNow();
        }
      });
    });
  }

  void _finishPracticeNow() {
    _bufferTimer?.cancel();
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
    _bufferTimer?.cancel();
    _engine.stopTimer();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showVisualPacer = widget.weaningStage < 3;
    bool showCounts = widget.weaningStage < 3;

    return Scaffold(
      backgroundColor: Colors.black, // Dark/subdued background for eyes-closed practice
      appBar: AppBar(
        title: Text(widget.practiceName),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _audioService.isVoiceEnabled ? Icons.record_voice_over : Icons.voice_over_off,
              color: Colors.white70,
            ),
            tooltip: 'Toggle Voice Guidance',
            onPressed: () {
              setState(() {
                _audioService.isVoiceEnabled = !_audioService.isVoiceEnabled;
              });
            },
          ),
        ],
      ),
      // Full-screen touch gestures enable hands-free / eyes-closed control anywhere on screen
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _togglePlay,
        onLongPress: _returnToNaturalBreath,
        onTap: () {
          // Re-announce current phase on tap if practicing blindly
          if (_isPlaying) {
            final cue = _audioEngine.getCueForPhaseTransition(
              phase: _currentPhase,
              cycleNumber: _engine.currentCycle,
            );
            _audioService.dispatchCue(cue);
          }
        },
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Settling Buffer View
                  if (_isSettling) ...[
                    Text(
                      'Settle Into Posture',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Rest hands in mudra and close your eyes.\nPractice begins in:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 24),
                    Text(
                      '${_audioEngine.settlingSecondsLeft}',
                      style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    SizedBox(height: 24),
                    TextButton(
                      onPressed: _skipSettling,
                      child: Text('Skip Countdown & Start', style: TextStyle(color: Colors.white60)),
                    ),
                  ]
                  // Post-Session Integration View
                  else if (_isIntegrating) ...[
                    Text(
                      'Silent Integration',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Keep your eyes closed.\nObserve stillness and natural breath.\nCompleting in ${_audioEngine.integrationSecondsLeft}s',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _finishPracticeNow,
                      child: Text('Open Eyes & Check-in'),
                    ),
                  ]
                  // Active Practice View
                  else ...[
                    if (widget.weaningStage > 1)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Weaning Stage ${widget.weaningStage} · ${_audioEngine.guidanceLevel.name}',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                        ),
                      ),
                    SizedBox(height: 16),
                    Text(
                      'Cycle ${_engine.currentCycle}',
                      style: TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                    SizedBox(height: 20),

                    if (showVisualPacer)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: _currentPhase == PracticePhase.puraka ? 200 : 130,
                        height: _currentPhase == PracticePhase.puraka ? 200 : 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPhase == PracticePhase.naturalBreath
                              ? Colors.green.withOpacity(0.2)
                              : Colors.teal.withOpacity(0.25),
                          border: Border.all(
                            color: _currentPhase == PracticePhase.naturalBreath
                                ? Colors.greenAccent
                                : Colors.tealAccent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _currentPhase.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'Hands-free Audio Mode\n(Eyes Closed)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white38),
                        ),
                      ),

                    SizedBox(height: 24),
                    if (showCounts)
                      Text(
                        '${_secondsElapsed}s',
                        style: TextStyle(fontSize: 48, color: Colors.white),
                      ),
                    SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (!_isPlaying && _secondsElapsed == 0) {
                              _startWithSettlingBuffer();
                            } else {
                              _togglePlay();
                            }
                          },
                          child: Text(_isPlaying ? 'Pause' : 'Start Practice'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                          onPressed: _returnToNaturalBreath,
                          child: Text('Natural Breath', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _startIntegrationBuffer,
                      child: Text('Complete Session', style: TextStyle(color: Colors.white70)),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Eyes-Closed Gestures:\nDouble-tap screen to Pause/Play · Long-press for Natural Breath',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
