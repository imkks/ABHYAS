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
                  SizedBox(height: 40),

                  // Circular Step Timer / Pacer
                  Container(
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
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _isPaused ? 'PAUSED' : 'REMAINING',
                            style: TextStyle(
                              color: _isPaused ? Colors.orange : AbhyasTheme.darkInkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

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
