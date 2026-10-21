import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptic_service.dart';
import '../../core/theme.dart';
import '../../engine/player/cycle_sequencer.dart';
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

  @override
  void initState() {
    super.initState();
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

        // Haptic and audio feedback
        _hapticService.pulseForMatra(widget.weaningStage);
        _audioService.playTick();
      },
      onStepComplete: (completedIndex) {
        _audioService.playBell(BellType.transition);
        _hapticService.phaseTransitionPulse(widget.weaningStage);
      },
      onCycleComplete: _handleCycleComplete,
    );
  }

  void _handleCycleComplete() {
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
        _sequencer.resume();
        _isPaused = false;
      } else {
        _sequencer.pause();
        _isPaused = true;
      }
    });
  }

  void _skipStep() {
    _sequencer.skipStep();
    _audioService.playBell(BellType.transition);
  }

  void _abortPractice() {
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
    final ratio = currentStep.ratio;
    final isPacer = currentStep.isPranayamaWithPacer && ratio != null && ratio.length >= 3;

    if (!isPacer) {
      // Standard countdown circle
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

    // Dynamic Pranayama Pacer (e.g. Nadi Shodhana with level-scaled Kumbhaka)
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
      if (currentStep.id.contains('nadi')) {
        nostrilCue = breathRound.isOdd ? 'Inhale Left (Ida)' : 'Inhale Right (Pingala)';
      } else {
        nostrilCue = 'Deep diaphragmatic breath';
      }
    } else if (secondInCycle < puraka + antar) {
      phaseTitle = 'ANTAR KUMBHAKA (HOLD)';
      phaseColor = AbhyasTheme.saffron;
      phaseTarget = antar;
      secondsInPhase = (secondInCycle - puraka) + 1;
      nostrilCue = currentStep.id.contains('nadi')
          ? 'Both Closed • Jalandhara Bandha'
          : 'Internal Hold • Throat Lock';
    } else if (secondInCycle < puraka + antar + rechaka) {
      phaseTitle = 'RECHAKA (EXHALE)';
      phaseColor = AbhyasTheme.clay;
      phaseTarget = rechaka;
      secondsInPhase = (secondInCycle - puraka - antar) + 1;
      if (currentStep.id.contains('nadi')) {
        nostrilCue = breathRound.isOdd ? 'Exhale Right (Pingala)' : 'Exhale Left (Ida)';
      } else {
        nostrilCue = 'Smooth, slow exhalation';
      }
    } else {
      phaseTitle = 'BAHYA KUMBHAKA (HOLD)';
      phaseColor = const Color(0xFF9D4EDD);
      phaseTarget = bahya;
      secondsInPhase = (secondInCycle - puraka - antar - rechaka) + 1;
      nostrilCue = 'External Hold • Maha Bandha';
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 200,
          height: 200,
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

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: Text('Cycle: Step ${_currentStepIndex + 1} of ${widget.steps.length}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
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
                  SizedBox(height: 6),
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

            Spacer(),

            // Active Step Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
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
                  SizedBox(height: 8),
                  Text(
                    currentStep.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    currentStep.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  _buildPacerOrTimer(currentStep, stepRemaining),
                ],
              ),
            ),

            const Spacer(),

            // Next step preview pill
            if (nextStep != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AbhyasTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AbhyasTheme.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.skip_next, size: 18, color: AbhyasTheme.sky),
                    SizedBox(width: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                    icon: Icon(Icons.skip_next, color: Colors.white70),
                    tooltip: 'Skip Step',
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
