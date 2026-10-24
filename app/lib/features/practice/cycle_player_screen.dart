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
    const roundDuration = 55; // 35s strokes + 10s Bahir Kumbhaka + 4s Puraka + 6s rest
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
    } else if (secInRound < 35) {
      // 35 active sharp exhalations (~1 per second)
      final strokeNum = secInRound + 1;
      phaseTitle = 'ROUND $currentRoundNum: ACTIVE EXHALATIONS';
      countText = 'Stroke $strokeNum/35';
      subtitle = 'Sharp abdominal pumping • Chin Mudra • Passive inhalation';
      phaseColor = AbhyasTheme.saffron;
    } else if (secInRound < 45) {
      // Bahir Kumbhaka (10s External Hold on Empty Lungs)
      final holdLeft = 45 - secInRound;
      phaseTitle = 'ROUND $currentRoundNum: BAHIR KUMBHAKA (HOLD EMPTY)';
      countText = '${holdLeft}s EMPTY';
      subtitle = 'Exhale completely • Hold outside • Maha Bandha (Chin & Navel lock)';
      phaseColor = const Color(0xFF9D4EDD);
    } else if (secInRound < 49) {
      // Deep Puraka Release (4s)
      final purakaSec = (secInRound - 45) + 1;
      phaseTitle = 'ROUND $currentRoundNum: PURAKA RELEASE';
      countText = '${purakaSec}s / 4s';
      subtitle = 'Release locks gently • Take one slow, deep diaphragmatic inhalation';
      phaseColor = AbhyasTheme.sky;
    } else {
      // Natural Breath Rest (6s)
      final recLeft = 55 - secInRound;
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
    final antarHold = (currentStep.ratio != null && currentStep.ratio!.length > 1) ? currentStep.ratio![1] : 0;
    final cycleTotal = 4 + antarHold + 5; // Puraka (4s) + [Antar Kumbhaka] + Rechaka (5s)
    final secInCycle = _stepSeconds % cycleTotal;
    final roundNum = (_stepSeconds ~/ cycleTotal) + 1;

    String phaseTitle;
    Color phaseColor;
    int secondsInPhase;
    int totalInPhase;
    String cue;

    if (secInCycle < 4) {
      // Inhale
      phaseTitle = 'UJJAYI PURAKA (OCEAN INHALE)';
      phaseColor = AbhyasTheme.sky;
      secondsInPhase = secInCycle + 1;
      totalInPhase = 4;
      cue = 'Gently constrict back of throat (glottis) • Soft ocean wave sound';
    } else if (antarHold > 0 && secInCycle < 4 + antarHold) {
      // Antar Kumbhaka (Advanced)
      phaseTitle = 'ANTAR KUMBHAKA (INTERNAL HOLD)';
      phaseColor = const Color(0xFF9D4EDD);
      secondsInPhase = (secInCycle - 4) + 1;
      totalInPhase = antarHold;
      cue = 'Gentle chin lock (Jalandhara Bandha) • Throat throat lock retention';
    } else {
      // Exhale
      phaseTitle = 'UJJAYI RECHAKA (OCEAN EXHALE)';
      phaseColor = AbhyasTheme.clay;
      secondsInPhase = (secInCycle - 4 - antarHold) + 1;
      totalInPhase = 5;
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

  /// 3-Stage Guided Naam Japa Pacer: Vaikhari (loud) -> Upamshu (murmur) -> Manasika (silent mind)
  Widget _buildNaamJapaPacer(CycleStepItem currentStep, int stepRemaining) {
    final totalDuration = currentStep.durationSeconds > 0 ? currentStep.durationSeconds : 480;
    final progress = (_stepSeconds / totalDuration).clamp(0.0, 1.0);

    String stageTitle;
    String stageDescription;
    Color stageColor;

    if (progress < 0.33) {
      stageTitle = 'STAGE 1: VAIKHARI (SPOKEN ALOUD)';
      stageDescription = 'Recite the sacred Naam out loud with devotion and clear resonance.';
      stageColor = AbhyasTheme.saffron;
    } else if (progress < 0.66) {
      stageTitle = 'STAGE 2: UPAMSHU (WHISPER / MURMUR)';
      stageDescription = 'Murmur the Naam softly with subtle lip movement so only you can hear.';
      stageColor = AbhyasTheme.sky;
    } else {
      stageTitle = 'STAGE 3: MANASIKA (SILENT INNER MIND)';
      stageDescription = 'Let the repetition become purely mental and effortless within inner space.';
      stageColor = const Color(0xFF9D4EDD);
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(
              color: _isPaused ? Colors.grey : stageColor,
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: stageColor.withValues(alpha: _isPaused ? 0.05 : 0.35),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const SizedBox(height: 8),
                Text(
                  _formatSeconds(stepRemaining),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
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
          child: Text(
            '3-Stage Progression: Vaikhari ➔ Upamshu ➔ Manasika',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
