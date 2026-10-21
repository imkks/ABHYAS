import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio/practice_audio_service.dart';
import '../../core/haptic_service.dart';
import '../../data/user_repository.dart';
import '../../engine/player/player_engine.dart';
import '../../engine/player/audio_guidance_engine.dart';
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
  late AudioGuidanceEngine _audioEngine;
  final PracticeAudioService _audioService = PracticeAudioService();
  final HapticService _hapticService = HapticService();

  late List<int> _activeRatio;
  PracticePhase _currentPhase = PracticePhase.puraka;
  int _secondsElapsed = 0;
  int _totalSecondsElapsed = 0;
  int _currentRound = 1;
  bool _isPlaying = false;
  bool _isSettling = false;
  bool _isIntegrating = false;
  Timer? _bufferTimer;

  @override
  void initState() {
    super.initState();
    _activeRatio = widget.ratio ?? [4, 0, 4, 0];

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

        var nextPhase = _engine.getNextPhase(_currentPhase);

        // Check if round completed
        final isRoundEnd = _currentPhase == PracticePhase.bahyaKumbhaka ||
            (_activeRatio[3] == 0 && _currentPhase == PracticePhase.rechaka);

        if (isRoundEnd) {
          _hapticService.roundCompletePulse(widget.weaningStage);
          if (_currentRound >= widget.rounds) {
            _startIntegrationBuffer();
            return;
          } else {
            _currentRound++;
          }
        }

        // Skip hold phases if ratio specifies 0
        if (nextPhase == PracticePhase.antarKumbhaka && _activeRatio[1] == 0) {
          nextPhase = PracticePhase.rechaka;
        } else if (nextPhase == PracticePhase.bahyaKumbhaka && _activeRatio[3] == 0) {
          nextPhase = PracticePhase.puraka;
        }

        _currentPhase = nextPhase;

        // Play phase audio transition cue (minimal speech + tonal earcon)
        final cue = _audioEngine.getCueForPhaseTransition(
          phase: _currentPhase,
          cycleNumber: _currentRound,
        );
        _audioService.dispatchCue(cue);
        _hapticService.phaseTransitionPulse(widget.weaningStage);

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
    _bufferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      cycleNumber: _currentRound,
    );
    _audioService.dispatchCue(cue);
    _hapticService.phaseTransitionPulse(widget.weaningStage);

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
          cycleNumber: _currentRound,
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
    _bufferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white70),
            tooltip: 'Finish Practice',
            onPressed: _startIntegrationBuffer,
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
              cycleNumber: _currentRound,
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
                    const Text(
                      'Settle Into Posture',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rest hands in mudra and close your eyes.\nPractice begins in:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${_audioEngine.settlingSecondsLeft}',
                      style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _skipSettling,
                      child: const Text('Skip Countdown & Start', style: TextStyle(color: Colors.white60)),
                    ),
                  ]
                  // Post-Session Integration View
                  else if (_isIntegrating) ...[
                    const Text(
                      'Silent Integration',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep your eyes closed.\nObserve stillness and natural breath.\nCompleting in ${_audioEngine.integrationSecondsLeft}s',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _finishPracticeNow,
                      child: const Text('Open Eyes & Check-in'),
                    ),
                  ]
                  // Active Practice View
                  else ...[
                    Text(
                      'Round $_currentRound of ${widget.rounds}',
                      style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ratio: ${_activeRatio.join(" : ")}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    if (widget.weaningStage > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Weaning Stage ${widget.weaningStage} · ${_audioEngine.guidanceLevel.name}',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 20),

                    if (showVisualPacer)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
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
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'Hands-free Audio Mode\n(Eyes Closed)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white38),
                        ),
                      ),

                    const SizedBox(height: 24),
                    if (showCounts)
                      Text(
                        '${_secondsElapsed}s',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white),
                      ),
                    const SizedBox(height: 30),

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
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(_isPlaying ? 'Pause' : 'Start Practice'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: _returnToNaturalBreath,
                          child: const Text('Natural Breath'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _startIntegrationBuffer,
                      child: const Text('Complete Session', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
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
