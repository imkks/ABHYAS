import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio/android_practice_playback.dart';
import '../../core/audio_service.dart';
import '../../core/haptic_service.dart';
import '../../core/theme.dart';
import '../../engine/meditation/meditation_engine.dart';
import '../../engine/player/cycle_sequencer.dart';
import '../../engine/player/player_engine.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'post_session_checkin_screen.dart';

class CyclePlayerScreen extends StatefulWidget {
  final List<CycleStepItem> steps;
  final SafetyProfile safetyProfile;
  final int weaningStage;

  const CyclePlayerScreen({
    super.key,
    required this.steps,
    required this.safetyProfile,
    this.weaningStage = 1,
  });

  @override
  State<CyclePlayerScreen> createState() => _CyclePlayerScreenState();
}

class _CyclePlayerScreenState extends State<CyclePlayerScreen> {
  late CycleSequencer _sequencer;
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();

  int _stepSeconds = 0;
  int _totalSeconds = 0;
  int _currentStepIndex = 0;
  bool _isPaused = false;
  String _lastPhaseKey = '';
  int _lastStepForCue = -1;

  // Exercise Transition Gap state
  bool _isTransitioning = false;
  int _transitionRemainingSeconds = 10;
  final int _transitionDurationSeconds = 10;
  int _completedStepIndex = -1;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    AndroidPracticePlayback.start();
    _sequencer = CycleSequencer(steps: widget.steps);

    _audioService.playBell(BellType.start);

    _sequencer.start(
      onTick: (stepIndex, stepSeconds, totalSeconds) {
        if (!mounted) return;
        setState(() {
          _currentStepIndex = stepIndex;
          _stepSeconds = stepSeconds;
          _totalSeconds = totalSeconds;
        });

        // Haptic feedback for matra pulse
        _hapticService.pulseForMatra(widget.weaningStage);

        // Precise phase transition sound cues aligned with breath pacing
        if (_currentStepIndex < widget.steps.length) {
          _checkAndPlayPhaseCue(widget.steps[_currentStepIndex], stepSeconds);
        }
      },
      onStepComplete: (completedIndex) {
        _lastPhaseKey = '';
        if (completedIndex + 1 < widget.steps.length) {
          _sequencer.pause();
          _startTransitionGap(completedIndex);
        } else {
          _audioService.playBell(BellType.transition);
          _hapticService.phaseTransitionPulse(widget.weaningStage);
        }
      },
      onCycleComplete: _handleCycleComplete,
    );
  }

  void _checkAndPlayPhaseCue(CycleStepItem currentStep, int stepSeconds) {
    if (_lastStepForCue != _currentStepIndex) {
      _lastStepForCue = _currentStepIndex;
      _lastPhaseKey = '';
    }

    final id = currentStep.id.toLowerCase();

    // 1. Kapalbhati
    if (id.contains('kapal')) {
      int strokes = 30;
      if (currentStep.subtitle.contains('45 strokes') || currentStep.subtitle.contains('45')) strokes = 45;
      if (currentStep.subtitle.contains('60 strokes') || currentStep.subtitle.contains('60')) strokes = 60;
      if (currentStep.subtitle.contains('80 strokes') || currentStep.subtitle.contains('80')) strokes = 80;

      int hold = 10;
      if (currentStep.ratio != null && currentStep.ratio!.length > 3 && currentStep.ratio![3] > 0) {
        hold = currentStep.ratio![3];
      } else if (currentStep.subtitle.contains('0s') || currentStep.subtitle.contains('No hold')) {
        hold = 0;
      } else if (currentStep.subtitle.contains('5s')) {
        hold = 5;
      } else if (currentStep.subtitle.contains('15s')) {
        hold = 15;
      }

      final roundDuration = strokes + hold + 4 + 6;
      final cycleNumber = stepSeconds ~/ roundDuration;
      final secInRound = stepSeconds % roundDuration;

      String currentPhaseKey;
      if (secInRound < strokes) {
        currentPhaseKey = 'kapal_strokes_$cycleNumber';
      } else if (secInRound < strokes + hold) {
        currentPhaseKey = 'kapal_bahir_$cycleNumber';
      } else if (secInRound < strokes + hold + 4) {
        currentPhaseKey = 'kapal_puraka_$cycleNumber';
      } else {
        currentPhaseKey = 'kapal_recovery_$cycleNumber';
      }

      if (currentPhaseKey != _lastPhaseKey) {
        _lastPhaseKey = currentPhaseKey;
        if (currentPhaseKey.startsWith('kapal_strokes')) {
          _audioService.playBell(BellType.start);
          _hapticService.phaseTransitionPulse(widget.weaningStage);
        } else if (currentPhaseKey.startsWith('kapal_bahir')) {
          _audioService.playPhaseCue(PracticePhase.bahyaKumbhaka);
          _hapticService.phaseTransitionPulse(widget.weaningStage);
        } else if (currentPhaseKey.startsWith('kapal_puraka')) {
          _audioService.playPhaseCue(PracticePhase.puraka);
          _hapticService.phaseTransitionPulse(widget.weaningStage);
        } else if (currentPhaseKey.startsWith('kapal_recovery')) {
          _audioService.playPhaseCue(PracticePhase.naturalBreath);
        }
      }
      return;
    }

    // 2. Bhramari
    if (id.contains('bhramari')) {
      final antarHold = (currentStep.ratio != null && currentStep.ratio!.length > 1) ? currentStep.ratio![1] : 0;
      const puraka = 4;
      const humming = 8;
      final cycleTotal = puraka + antarHold + humming;
      final cycleNumber = stepSeconds ~/ cycleTotal;
      final secInCycle = stepSeconds % cycleTotal;

      String currentPhaseKey;
      PracticePhase currentPhase;
      if (secInCycle < puraka) {
        currentPhaseKey = 'bhramari_puraka_$cycleNumber';
        currentPhase = PracticePhase.puraka;
      } else if (antarHold > 0 && secInCycle < puraka + antarHold) {
        currentPhaseKey = 'bhramari_antar_$cycleNumber';
        currentPhase = PracticePhase.antarKumbhaka;
      } else {
        currentPhaseKey = 'bhramari_humming_$cycleNumber';
        currentPhase = PracticePhase.rechaka;
      }

      if (currentPhaseKey != _lastPhaseKey) {
        _lastPhaseKey = currentPhaseKey;
        _audioService.playPhaseCue(currentPhase);
        _hapticService.phaseTransitionPulse(widget.weaningStage);
      }
      return;
    }

    // 3. Ujjayi
    if (id.contains('ujjayi')) {
      final puraka = (currentStep.ratio != null && currentStep.ratio!.isNotEmpty) ? currentStep.ratio![0] : 4;
      final antarHold = (currentStep.ratio != null && currentStep.ratio!.length > 1) ? currentStep.ratio![1] : 0;
      final rechaka = (currentStep.ratio != null && currentStep.ratio!.length > 2)
          ? currentStep.ratio![2]
          : (currentStep.subtitle.contains('4s : 8s') ? 8 : (currentStep.subtitle.contains('5s : 5s') ? 5 : 4));
      final cycleTotal = puraka + antarHold + rechaka;
      final cycleNumber = stepSeconds ~/ cycleTotal;
      final secInCycle = stepSeconds % cycleTotal;

      String currentPhaseKey;
      PracticePhase currentPhase;
      if (secInCycle < puraka) {
        currentPhaseKey = 'ujjayi_puraka_$cycleNumber';
        currentPhase = PracticePhase.puraka;
      } else if (antarHold > 0 && secInCycle < puraka + antarHold) {
        currentPhaseKey = 'ujjayi_antar_$cycleNumber';
        currentPhase = PracticePhase.antarKumbhaka;
      } else {
        currentPhaseKey = 'ujjayi_rechaka_$cycleNumber';
        currentPhase = PracticePhase.rechaka;
      }

      if (currentPhaseKey != _lastPhaseKey) {
        _lastPhaseKey = currentPhaseKey;
        _audioService.playPhaseCue(currentPhase);
        _hapticService.phaseTransitionPulse(widget.weaningStage);
      }
      return;
    }

    // 4. Nadi Shodhana (or 4-part breath ratio)
    if (id.contains('nadi') || (currentStep.isPranayamaWithPacer && currentStep.ratio != null && currentStep.ratio!.length >= 3)) {
      final ratio = currentStep.ratio ?? [4, 8, 8, 4];
      final puraka = ratio[0];
      final antar = ratio[1];
      final rechaka = ratio[2];
      final bahya = ratio.length > 3 ? ratio[3] : 0;
      final cycleTotal = puraka + antar + rechaka + bahya;
      if (cycleTotal <= 0) return;

      final cycleNumber = stepSeconds ~/ cycleTotal;
      final secInCycle = stepSeconds % cycleTotal;

      String currentPhaseKey;
      PracticePhase currentPhase;
      if (secInCycle < puraka) {
        currentPhaseKey = 'nadi_puraka_$cycleNumber';
        currentPhase = PracticePhase.puraka;
      } else if (secInCycle < puraka + antar) {
        currentPhaseKey = 'nadi_antar_$cycleNumber';
        currentPhase = PracticePhase.antarKumbhaka;
      } else if (secInCycle < puraka + antar + rechaka) {
        currentPhaseKey = 'nadi_rechaka_$cycleNumber';
        currentPhase = PracticePhase.rechaka;
      } else {
        currentPhaseKey = 'nadi_bahya_$cycleNumber';
        currentPhase = PracticePhase.bahyaKumbhaka;
      }

      if (currentPhaseKey != _lastPhaseKey) {
        _lastPhaseKey = currentPhaseKey;
        _audioService.playPhaseCue(currentPhase);
        _hapticService.phaseTransitionPulse(widget.weaningStage);
      }
      return;
    }

    // 5. 3-Stage Naam Japa / Sacred Mantra Meditation
    if (id.contains('naam') || id.contains('japa') || id.contains('jaap') || currentStep.title.toLowerCase().contains('naam') || currentStep.title.toLowerCase().contains('japa')) {
      final totalDuration = currentStep.durationSeconds > 0 ? currentStep.durationSeconds : 360;
      final vaikhariEnd = (totalDuration * 0.33).round();
      final upamshuEnd = (totalDuration * 0.66).round();
      final layaStart = totalDuration > 120 ? totalDuration - 30 : totalDuration - 10;

      String currentPhaseKey;
      JapaStage currentStage;

      if (stepSeconds < vaikhariEnd) {
        currentPhaseKey = 'naam_vaikhari';
        currentStage = JapaStage.vaikhari;
      } else if (stepSeconds < upamshuEnd) {
        currentPhaseKey = 'naam_upamshu';
        currentStage = JapaStage.upamshu;
      } else if (stepSeconds < layaStart) {
        currentPhaseKey = 'naam_manasika';
        currentStage = JapaStage.manasika;
      } else {
        currentPhaseKey = 'naam_laya';
        currentStage = JapaStage.laya;
      }

      if (currentPhaseKey != _lastPhaseKey) {
        _lastPhaseKey = currentPhaseKey;
        _audioService.playNaamJapaPhase(currentStage);

        // Tactile sensory confirmation corresponding to sound density
        if (currentStage == JapaStage.vaikhari) {
          _hapticService.phaseTransitionPulse(widget.weaningStage);
        } else if (currentStage == JapaStage.upamshu) {
          _hapticService.phaseTransitionPulse(widget.weaningStage);
          Future.delayed(const Duration(milliseconds: 250), () {
            _hapticService.pulseForMatra(widget.weaningStage);
          });
        } else if (currentStage == JapaStage.manasika) {
          _hapticService.pulseForMatra(widget.weaningStage);
          Future.delayed(const Duration(milliseconds: 200), () {
            _hapticService.pulseForMatra(widget.weaningStage);
          });
        } else {
          _hapticService.completionPulse();
        }
      }
      return;
    }
  }

  void _startTransitionGap(int completedIndex) {
    _transitionTimer?.cancel();
    setState(() {
      _isTransitioning = true;
      _completedStepIndex = completedIndex;
      _transitionRemainingSeconds = _transitionDurationSeconds;
    });

    // Deep grounding bell cue signaling exercise completion and returning to natural breath
    _audioService.playBell(BellType.transition);
    _hapticService.phaseTransitionPulse(widget.weaningStage);

    _transitionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isPaused) return;

      setState(() {
        if (_transitionRemainingSeconds > 1) {
          _transitionRemainingSeconds--;
          // Soft ticks at 3, 2, 1 seconds to prepare practitioner
          if (_transitionRemainingSeconds <= 3) {
            _audioService.playTick();
            _hapticService.pulseForMatra(widget.weaningStage);
          }
        } else {
          _finishTransitionAndStartNext();
        }
      });
    });
  }

  void _finishTransitionAndStartNext() {
    _transitionTimer?.cancel();
    _transitionTimer = null;
    setState(() {
      _isTransitioning = false;
    });

    _lastPhaseKey = '';
    _audioService.playBell(BellType.start);
    _hapticService.completionPulse();
    _sequencer.resume();
  }

  String _getMudraAndPrepGuidance(CycleStepItem step) {
    final id = step.id.toLowerCase();
    final title = step.title.toLowerCase();

    if (id.contains('nadi') || title.contains('nadi') || title.contains('alternate')) {
      return 'Return to natural breath · Rest left hand in Chin Mudra · Raise right hand into Vishnu Mudra (Nasagra)';
    }
    if (id.contains('kapal') || title.contains('kapal')) {
      return 'Sit upright with spine erect · Rest hands in Chin Mudra on knees · Relax abdominal wall';
    }
    if (id.contains('bhramari') || title.contains('bhramari')) {
      return 'Relax facial muscles · Prepare Shanmukhi Mudra or gently place thumbs on the ear tragi';
    }
    if (id.contains('ujjayi') || title.contains('ujjayi')) {
      return 'Sit comfortably upright · Relax throat and jaw · Rest hands in Jnana Mudra';
    }
    if (id.contains('bhastrika') || title.contains('bhastrika')) {
      return 'Straighten spine · Hands on knees in Chin Mudra · Prepare for active bellows respiration';
    }
    if (id.contains('sheetali') || title.contains('sheetali') || id.contains('sheetkari') || title.contains('sheetkari')) {
      return 'Roll tongue into a tube or gently clench teeth · Rest hands in Jnana Mudra on knees';
    }
    if (id.contains('naam') || id.contains('japa') || id.contains('jaap') || title.contains('naam') || title.contains('japa') || title.contains('jaap')) {
      return 'Close eyes softly · Hands in Dhyana Mudra · Prepare for 3-Stage sacred sound immersion';
    }
    if (id.contains('breath_awareness') || id.contains('dhyan') || id.contains('nostril') || title.contains('dhyan') || title.contains('awareness')) {
      return 'Keep eyes gently closed · Settle awareness at nostril rims · Witness natural incoming & outgoing breath';
    }
    if (id.contains('nidra') || id.contains('savasana') || title.contains('nidra') || title.contains('savasana')) {
      return 'Lie flat on back in Savasana · Arms by sides, palms facing up · Surrender bodily weight to the earth';
    }
    if (step.subtitle.isNotEmpty) {
      return 'Return to natural breath · ${step.subtitle}';
    }
    return 'Take 2 natural calming breaths · Adjust your posture and mudra for the upcoming practice';
  }

  void _handleCycleComplete() {
    _transitionTimer?.cancel();
    _transitionTimer = null;
    AndroidPracticePlayback.stop();
    _audioService.playBell(BellType.end);
    _hapticService.completionPulse();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PostSessionCheckinScreen(
          safetyProfile: widget.safetyProfile,
          practiceName: 'Full Sadhana Cycle (${widget.steps.length} steps)',
          level: 2,
          durationSeconds: _totalSeconds,
        ),
      ),
    );
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        AndroidPracticePlayback.start();
        if (!_isTransitioning) {
          _sequencer.resume();
        }
        _isPaused = false;
      } else {
        AndroidPracticePlayback.stop();
        if (!_isTransitioning) {
          _sequencer.pause();
        }
        _isPaused = true;
      }
    });
  }

  void _skipStep() {
    if (_isTransitioning) {
      _finishTransitionAndStartNext();
      return;
    }
    _sequencer.skipStep();
  }

  void _abortPractice() {
    _transitionTimer?.cancel();
    _transitionTimer = null;
    AndroidPracticePlayback.stop();
    _sequencer.stop();
    _audioService.stopAll();
    Navigator.pop(context);
  }

  String _formatSeconds(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPacerOrTimer(CycleStepItem currentStep, int stepRemaining) {
    final id = currentStep.id.toLowerCase();

    // 1. Kapalbhati: Cleansing active strokes + deep Puraka + 10s soft Antar Kumbhaka
    if (id.contains('kapal')) {
      return _buildKapalbhatiPacer(currentStep, stepRemaining);
    }

    // 2. Bhramari: Shanmukhi Mudra with humming bee cranial resonance
    if (id.contains('bhramari')) {
      return _buildBhramariPacer(currentStep, stepRemaining);
    }

    // 3. Ujjayi: Ocean wave breath with glottis throat whisper
    if (id.contains('ujjayi')) {
      return _buildUjjayiPacer(currentStep, stepRemaining);
    }

    // 4. Nostril Dhyan / Breath Awareness: Jnana Mudra stillness at nostril rims & Ajna Chakra
    if (id.contains('breath_awareness') || id.contains('dhyan') || id.contains('nostril')) {
      return _buildNostrilDhyanPacer(currentStep, stepRemaining);
    }

    // 5. 3-Stage Naam Japa: Vaikhari (loud) -> Upamshu (whisper) -> Manasika (silent mind)
    if (id.contains('naam') || id.contains('japa') || id.contains('jaap')) {
      return _buildNaamJapaPacer(currentStep, stepRemaining);
    }

    // 6. Nadi Shodhana / Ratio Pranayama: Vishnu Mudra alternate nostril ratios
    if (id.contains('nadi') || (currentStep.isPranayamaWithPacer && currentStep.ratio != null && currentStep.ratio!.length >= 3)) {
      return _buildNadiShodhanaPacer(currentStep, stepRemaining, currentStep.ratio ?? [4, 8, 8, 4]);
    }

    // 7. Default step timer (Sankalp, Sukshma Vyayama, Yoga Nidra, Savasana, Shanti Path)
    return _buildDefaultTimer(currentStep, stepRemaining);
  }

  /// Kapalbhati Specialized Pacer: 3 Rounds (Strokes -> Bahir Kumbhaka (Empty Hold) -> Puraka -> Relax)
  Widget _buildKapalbhatiPacer(CycleStepItem currentStep, int stepRemaining) {
    int strokes = 30;
    if (currentStep.subtitle.contains('45 strokes') || currentStep.subtitle.contains('45')) strokes = 45;
    if (currentStep.subtitle.contains('60 strokes') || currentStep.subtitle.contains('60')) strokes = 60;
    if (currentStep.subtitle.contains('80 strokes') || currentStep.subtitle.contains('80')) strokes = 80;

    int hold = 10;
    if (currentStep.ratio != null && currentStep.ratio!.length > 3 && currentStep.ratio![3] > 0) {
      hold = currentStep.ratio![3];
    } else if (currentStep.subtitle.contains('0s') || currentStep.subtitle.contains('No hold')) {
      hold = 0;
    } else if (currentStep.subtitle.contains('5s')) {
      hold = 5;
    } else if (currentStep.subtitle.contains('15s')) {
      hold = 15;
    }

    final roundDuration = strokes + hold + 4 + 6; // Strokes + Bahir Kumbhaka + 4s Puraka + 6s rest
    final currentRoundNum = (_stepSeconds ~/ roundDuration) + 1;
    final secInRound = _stepSeconds % roundDuration;

    String phaseTitle;
    String countText;
    String subtitle;
    Color phaseColor;

    if (currentRoundNum > 3) {
      phaseTitle = 'KAPALBHATI COMPLETE';
      countText = 'STILL';
      subtitle = 'Rest in natural breath • Observe frontal brain luminosity (Kapala Bhati)';
      phaseColor = Colors.tealAccent;
    } else if (secInRound < strokes) {
      // Active sharp exhalations (~1 per second)
      final strokeNum = secInRound + 1;
      phaseTitle = 'ROUND $currentRoundNum: ACTIVE EXHALATIONS';
      countText = 'Stroke $strokeNum/$strokes';
      subtitle = 'Sharp abdominal pumping • Chin Mudra • Passive inhalation';
      phaseColor = AbhyasTheme.saffron;
    } else if (hold > 0 && secInRound < strokes + hold) {
      // Bahir Kumbhaka (External Hold on Empty Lungs)
      final holdLeft = (strokes + hold) - secInRound;
      phaseTitle = 'ROUND $currentRoundNum: BAHIR KUMBHAKA (HOLD EMPTY)';
      countText = '${holdLeft}s EMPTY';
      subtitle = 'Exhale completely • Hold outside • Maha Bandha (Chin & Navel lock)';
      phaseColor = const Color(0xFF9D4EDD);
    } else if (secInRound < strokes + hold + 4) {
      // Deep Puraka Release (4s)
      final purakaSec = (secInRound - (strokes + hold)) + 1;
      phaseTitle = 'ROUND $currentRoundNum: PURAKA RELEASE';
      countText = '${purakaSec}s / 4s';
      subtitle = 'Release locks gently • Take one slow, deep diaphragmatic inhalation';
      phaseColor = AbhyasTheme.sky;
    } else {
      // Natural Breath Rest (6s)
      final recLeft = roundDuration - secInRound;
      phaseTitle = 'ROUND $currentRoundNum: NATURAL REST';
      countText = '${recLeft}s';
      subtitle = 'Breathe naturally • Feel still prana before next round';
      phaseColor = Colors.tealAccent;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : phaseColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: _isPaused ? 0.05 : 0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseTitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: phaseColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Round ${currentRoundNum.clamp(1, 3)} of 3 · Chin Mudra',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Step Left: ${_formatSeconds(stepRemaining)}',
                style: const TextStyle(fontSize: 11, color: AbhyasTheme.darkInkSoft),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bhramari Specialized Pacer: Shanmukhi Mudra & Humming Bee with optional Antar Kumbhaka
  Widget _buildBhramariPacer(CycleStepItem currentStep, int stepRemaining) {
    final antarHold = (currentStep.ratio != null && currentStep.ratio!.length > 1) ? currentStep.ratio![1] : 0;
    final cycleTotal = 4 + antarHold + 8; // Puraka (4s) + [Antar Kumbhaka] + Humming (8s)
    final secInCycle = _stepSeconds % cycleTotal;
    final roundNum = (_stepSeconds ~/ cycleTotal) + 1;

    String phaseTitle;
    Color phaseColor;
    int secondsInPhase;
    int totalInPhase;
    String cue;

    if (secInCycle < 4) {
      // Inhale
      phaseTitle = 'PURAKA (SMOOTH INHALE)';
      phaseColor = AbhyasTheme.sky;
      secondsInPhase = secInCycle + 1;
      totalInPhase = 4;
      cue = 'Shanmukhi Mudra · Deep smooth Ujjayi inhalation';
    } else if (antarHold > 0 && secInCycle < 4 + antarHold) {
      // Antar Kumbhaka (Advanced)
      phaseTitle = 'ANTAR KUMBHAKA (INTERNAL HOLD)';
      phaseColor = const Color(0xFF9D4EDD);
      secondsInPhase = (secInCycle - 4) + 1;
      totalInPhase = antarHold;
      cue = 'Shanmukhi Mudra · Soft internal retention · Stillness at brow';
    } else {
      // Humming Exhale
      phaseTitle = 'BHRAMARI RECHAKA (HUMMING)';
      phaseColor = AbhyasTheme.saffron;
      secondsInPhase = (secInCycle - 4 - antarHold) + 1;
      totalInPhase = 8;
      cue = 'Close ears with thumbs · Long humming (Mmm...) vibrating skull';
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : phaseColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: _isPaused ? 0.05 : 0.35),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseTitle,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: phaseColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${secondsInPhase}s',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'of ${totalInPhase}s',
                  style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    cue,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Breath $roundNum · Shanmukhi Mudra ${antarHold > 0 ? "(Hold $antarHold s)" : ""}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Left: ${_formatSeconds(stepRemaining)}',
                style: const TextStyle(fontSize: 11, color: AbhyasTheme.darkInkSoft),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Ujjayi Specialized Pacer: Ocean Wave Whispering Breath with optional Antar Kumbhaka
  Widget _buildUjjayiPacer(CycleStepItem currentStep, int stepRemaining) {
    final puraka = (currentStep.ratio != null && currentStep.ratio!.isNotEmpty && currentStep.ratio![0] > 0)
        ? currentStep.ratio![0]
        : (currentStep.subtitle.contains('5s') ? 5 : 4);
    final antarHold = (currentStep.ratio != null && currentStep.ratio!.length > 1) ? currentStep.ratio![1] : 0;
    final rechaka = (currentStep.ratio != null && currentStep.ratio!.length > 2 && currentStep.ratio![2] > 0)
        ? currentStep.ratio![2]
        : (currentStep.subtitle.contains('4s : 8s') ? 8 : (currentStep.subtitle.contains('5s : 5s') ? 5 : 4));
    final cycleTotal = puraka + antarHold + rechaka;
    final secInCycle = _stepSeconds % cycleTotal;
    final roundNum = (_stepSeconds ~/ cycleTotal) + 1;

    String phaseTitle;
    Color phaseColor;
    int secondsInPhase;
    int totalInPhase;
    String cue;

    if (secInCycle < puraka) {
      // Inhale
      phaseTitle = 'UJJAYI PURAKA (OCEAN INHALE)';
      phaseColor = AbhyasTheme.sky;
      secondsInPhase = secInCycle + 1;
      totalInPhase = puraka;
      cue = 'Gently constrict back of throat (glottis) • Soft ocean wave sound';
    } else if (antarHold > 0 && secInCycle < puraka + antarHold) {
      // Antar Kumbhaka (Advanced)
      phaseTitle = 'ANTAR KUMBHAKA (INTERNAL HOLD)';
      phaseColor = const Color(0xFF9D4EDD);
      secondsInPhase = (secInCycle - puraka) + 1;
      totalInPhase = antarHold;
      cue = 'Gentle chin lock (Jalandhara Bandha) • Throat lock retention';
    } else {
      // Exhale
      phaseTitle = 'UJJAYI RECHAKA (OCEAN EXHALE)';
      phaseColor = AbhyasTheme.clay;
      secondsInPhase = (secInCycle - puraka - antarHold) + 1;
      totalInPhase = rechaka;
      cue = 'Smooth continuous exhalation like calm ocean surf';
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : phaseColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: _isPaused ? 0.05 : 0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseTitle,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: phaseColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${secondsInPhase}s',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'of ${totalInPhase}s',
                  style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    cue,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Breath $roundNum · Throat Resonance ${antarHold > 0 ? "(Hold $antarHold s)" : ""}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Left: ${_formatSeconds(stepRemaining)}',
                style: const TextStyle(fontSize: 11, color: AbhyasTheme.darkInkSoft),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Nostril Dhyan & Prana Dharana Pacer: Witnessing natural breath touch at nostril rim
  Widget _buildNostrilDhyanPacer(CycleStepItem currentStep, int stepRemaining) {
    const cycleTotal = 8; // 4s natural expansion, 4s natural settling
    final secInCycle = _stepSeconds % cycleTotal;
    final isInflow = secInCycle < 4;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : Colors.tealAccent,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: _isPaused ? 0.05 : 0.25),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PRANA DHARANA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatSeconds(stepRemaining),
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    isInflow
                        ? 'Feel cool touch of breath entering nostrils'
                        : 'Feel warm touch of breath gently leaving nostrils',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.tealAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AbhyasTheme.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AbhyasTheme.line),
          ),
          child: const Text(
            'Jnana Mudra · Observe complete stillness at brow center (Ajna Chakra)',
            style: TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 3-Stage Guided Naam Japa Pacer: Vaikhari (loud) -> Upamshu (murmur) -> Manasika (silent mind) -> Laya Stillness
  Widget _buildNaamJapaPacer(CycleStepItem currentStep, int stepRemaining) {
    final totalDuration = currentStep.durationSeconds > 0 ? currentStep.durationSeconds : 480;
    final progress = (_stepSeconds / totalDuration).clamp(0.0, 1.0);

    // Extract mantra name
    String sacredNaam = 'Radha Radha';
    String devanagari = 'राधा राधा';
    if (currentStep.subtitle.contains('Om Namah Shivaya')) {
      sacredNaam = 'Om Namah Shivaya';
      devanagari = 'ॐ नमः शिवाय';
    } else if (currentStep.subtitle.contains('So-Hum')) {
      sacredNaam = 'So-Hum';
      devanagari = 'सो ऽहम्';
    } else if (currentStep.subtitle.contains('Hare Krishna')) {
      sacredNaam = 'Hare Krishna';
      devanagari = 'हरे कृष्ण हरे राम';
    } else if (currentStep.subtitle.contains('Gayatri')) {
      sacredNaam = 'Gayatri Mantra';
      devanagari = 'ॐ भूर्भुवः स्वः';
    } else if (currentStep.subtitle.contains('Ram')) {
      sacredNaam = 'Sri Ram';
      devanagari = 'श्री राम जय राम';
    } else if (currentStep.subtitle.contains('Om')) {
      sacredNaam = 'Om';
      devanagari = 'ॐ';
    }

    String stageTitle;
    String stageDescription;
    Color stageColor;
    int activeStageIndex = 0; // 0: Vaikhari, 1: Upamshu, 2: Manasika, 3: Laya

    final isLaya = stepRemaining <= (totalDuration > 120 ? 30 : 10);

    if (isLaya) {
      stageTitle = 'STAGE 4: LAYA STILLNESS (ABSORPTION)';
      stageDescription = 'Release all recitation. Rest in the vibrant inner silence within.';
      stageColor = Colors.tealAccent;
      activeStageIndex = 3;
    } else if (progress < 0.33) {
      stageTitle = 'STAGE 1: VAIKHARI (SPOKEN ALOUD)';
      stageDescription = 'Recite the sacred Naam out loud with clear devotion and vocal resonance.';
      stageColor = AbhyasTheme.saffron;
      activeStageIndex = 0;
    } else if (progress < 0.66) {
      stageTitle = 'STAGE 2: UPAMSHU (WHISPER / MURMUR)';
      stageDescription = 'Murmur softly with subtle lip vibration so only you can hear.';
      stageColor = AbhyasTheme.sky;
      activeStageIndex = 1;
    } else {
      stageTitle = 'STAGE 3: MANASIKA (SILENT INNER MIND)';
      stageDescription = 'Still lips and tongue completely. Let the mantra repeat in pure mental silence.';
      stageColor = const Color(0xFFB57EDC);
      activeStageIndex = 2;
    }

    return Column(
      children: [
        // Stage Indicator Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStageIndicatorChip('1. Vaikhari (Aloud)', activeStageIndex == 0, AbhyasTheme.saffron),
            const SizedBox(width: 6),
            _buildStageIndicatorChip('2. Upamshu (Whisper)', activeStageIndex == 1, AbhyasTheme.sky),
            const SizedBox(width: 6),
            _buildStageIndicatorChip('3. Manasika (Mind)', activeStageIndex >= 2, const Color(0xFFB57EDC)),
          ],
        ),

        const SizedBox(height: 18),

        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : stageColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: stageColor.withValues(alpha: _isPaused ? 0.05 : 0.4),
                blurRadius: 36,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stageTitle,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: stageColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  devanagari,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSeconds(stepRemaining),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    stageDescription,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: stageColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AbhyasTheme.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AbhyasTheme.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up, size: 14, color: stageColor),
              const SizedBox(width: 8),
              Text(
                'Sacred Naam: $sacredNaam · Audio Cued Phase Flow',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageIndicatorChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? color : Colors.white24, width: isActive ? 1.5 : 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.white : Colors.white54,
        ),
      ),
    );
  }

  /// Nadi Shodhana Dynamic Pacer with Vishnu Mudra
  Widget _buildNadiShodhanaPacer(CycleStepItem currentStep, int stepRemaining, List<int> ratio) {
    final puraka = ratio[0];
    final antar = ratio[1];
    final rechaka = ratio[2];
    final bahya = ratio.length > 3 ? ratio[3] : 0;
    final cycleTotal = puraka + antar + rechaka + bahya;

    if (cycleTotal == 0) {
      return const SizedBox.shrink();
    }

    final secondInCycle = _stepSeconds % cycleTotal;
    final breathRound = (_stepSeconds ~/ cycleTotal) + 1;

    String phaseTitle;
    String nostrilCue;
    Color phaseColor;
    int phaseTarget;
    int secondsInPhase;

    if (secondInCycle < puraka) {
      phaseTitle = 'PURAKA (INHALE)';
      phaseColor = AbhyasTheme.sky;
      phaseTarget = puraka;
      secondsInPhase = secondInCycle + 1;
      nostrilCue = breathRound.isOdd
          ? 'Inhale Left (Ida) • Thumb closes right nostril'
          : 'Inhale Right (Pingala) • Ring finger closes left';
    } else if (secondInCycle < puraka + antar) {
      phaseTitle = 'ANTAR KUMBHAKA (HOLD)';
      phaseColor = AbhyasTheme.saffron;
      phaseTarget = antar;
      secondsInPhase = (secondInCycle - puraka) + 1;
      nostrilCue = 'Both Nostrils Closed • Jalandhara Bandha (Chin Lock)';
    } else if (secondInCycle < puraka + antar + rechaka) {
      phaseTitle = 'RECHAKA (EXHALE)';
      phaseColor = AbhyasTheme.clay;
      phaseTarget = rechaka;
      secondsInPhase = (secondInCycle - puraka - antar) + 1;
      nostrilCue = breathRound.isOdd
          ? 'Exhale Right (Pingala) • Release right thumb'
          : 'Exhale Left (Ida) • Release left ring finger';
    } else {
      phaseTitle = 'BAHYA KUMBHAKA (HOLD)';
      phaseColor = const Color(0xFF9D4EDD);
      phaseTarget = bahya;
      secondsInPhase = (secondInCycle - puraka - antar - rechaka) + 1;
      nostrilCue = 'Both Nostrils Closed • Hold Empty • Maha Bandha';
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : phaseColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: _isPaused ? 0.05 : 0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseTitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${secondsInPhase}s',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'of ${phaseTarget}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AbhyasTheme.darkInkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    nostrilCue,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Ratio: ${ratio.join(":")} · Round $breathRound',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.line),
              ),
              child: Text(
                'Left: ${_formatSeconds(stepRemaining)}',
                style: const TextStyle(fontSize: 11, color: AbhyasTheme.darkInkSoft),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Default countdown circle for preparation & restorative steps
  Widget _buildDefaultTimer(CycleStepItem currentStep, int stepRemaining) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AbhyasTheme.darkSurface,
        border: Border.all(
          color: _isPaused ? Colors.grey : AbhyasTheme.saffron,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AbhyasTheme.saffron.withValues(alpha: _isPaused ? 0.05 : 0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatSeconds(stepRemaining),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              _isPaused ? 'PAUSED' : 'REMAINING',
              style: const TextStyle(
                color: AbhyasTheme.darkInkSoft,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionView(CycleStepItem completedStep, CycleStepItem nextStep) {
    final prepGuidance = _getMudraAndPrepGuidance(nextStep);
    final progress = (1.0 - (_transitionRemainingSeconds / _transitionDurationSeconds)).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AbhyasTheme.saffron.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle_outline, size: 16, color: AbhyasTheme.saffron),
              const SizedBox(width: 8),
              Text(
                'EXERCISE TRANSITION · REST BUFFER',
                style: TextStyle(
                  color: AbhyasTheme.saffron,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Completed practice confirmation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 15, color: Colors.tealAccent),
            const SizedBox(width: 6),
            Text(
              'Completed: ${completedStep.title}',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Upcoming practice title
        Text(
          'SWITCH TO:',
          style: TextStyle(
            color: AbhyasTheme.darkInkSoft,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            nextStep.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Countdown Circular Ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: AbhyasTheme.darkSurfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _transitionRemainingSeconds <= 3 ? Colors.amberAccent : AbhyasTheme.saffron,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_transitionRemainingSeconds',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w200,
                    color: _transitionRemainingSeconds <= 3 ? Colors.amberAccent : Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _transitionRemainingSeconds <= 3 ? 'Get Ready...' : 'Natural breath...',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _transitionRemainingSeconds <= 3 ? Colors.amberAccent : AbhyasTheme.darkInkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Mudra & Posture Guidance Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AbhyasTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.self_improvement, color: AbhyasTheme.saffron, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POSTURE & MUDRA PREPARATION',
                      style: TextStyle(
                        color: AbhyasTheme.saffron,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      prepGuidance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Begin Now Skip Button
        ElevatedButton.icon(
          onPressed: _finishTransitionAndStartNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AbhyasTheme.saffron,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 3,
          ),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: Text(
            'Begin ${nextStep.title} Now ➔',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    AndroidPracticePlayback.stop();
    _sequencer.stop();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _sequencer.currentStep;
    final hasNext = _currentStepIndex + 1 < widget.steps.length;
    final nextStep = hasNext ? widget.steps[_currentStepIndex + 1] : null;

    final stepRemaining = (currentStep.durationSeconds - _stepSeconds).clamp(0, currentStep.durationSeconds);

    final completedStep = _completedStepIndex >= 0 && _completedStepIndex < widget.steps.length
        ? widget.steps[_completedStepIndex]
        : currentStep;

    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: Text(
          _isTransitioning
              ? 'Transition · Prepare Step ${_currentStepIndex + 1} of ${widget.steps.length}'
              : 'Cycle: Step ${_currentStepIndex + 1} of ${widget.steps.length}',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _abortPractice,
            tooltip: 'Exit Practice',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Overall Cycle Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Time: ${_formatSeconds(_totalSeconds)}',
                        style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                      ),
                      Text(
                        '${(_sequencer.overallProgress * 100).toInt()}% completed',
                        style: TextStyle(color: AbhyasTheme.saffron, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _sequencer.overallProgress,
                    backgroundColor: AbhyasTheme.darkSurfaceAlt,
                    color: AbhyasTheme.saffron,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            // Center Scrollable Area (guarantees zero RenderFlex overflow)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: _isTransitioning
                      ? _buildTransitionView(completedStep, currentStep)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'STEP ${_currentStepIndex + 1}',
                              style: TextStyle(
                                color: AbhyasTheme.sky,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentStep.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentStep.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
                            ),
                            const SizedBox(height: 20),

                            _buildPacerOrTimer(currentStep, stepRemaining),
                          ],
                        ),
                ),
              ),
            ),

            // Next step preview pill (only when not in transition)
            if (!_isTransitioning && nextStep != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AbhyasTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AbhyasTheme.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.skip_next, size: 18, color: AbhyasTheme.sky),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Up next: ${nextStep.title} (${_formatSeconds(nextStep.durationSeconds)})',
                        style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Abort / Return to natural breath
                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.stop_circle_outlined, color: AbhyasTheme.clay),
                    tooltip: 'Abort Practice',
                    onPressed: _abortPractice,
                  ),

                  // Play / Pause
                  FloatingActionButton.large(
                    backgroundColor: AbhyasTheme.saffron,
                    foregroundColor: Colors.black,
                    onPressed: _togglePause,
                    child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 40),
                  ),

                  // Skip to next step
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next, color: Colors.white70),
                    tooltip: _isTransitioning ? 'Begin Step Now' : 'Skip Step',
                    onPressed: _skipStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
