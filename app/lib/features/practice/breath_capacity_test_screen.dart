import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio_service.dart';
import '../../core/haptic_service.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/progression/progression_service.dart';
import 'cycle_composer_screen.dart';

enum TestPhase {
  intro,
  centering,
  inhale,
  holding,
  completed,
}

class BreathCapacityTestScreen extends StatefulWidget {
  const BreathCapacityTestScreen({super.key});

  @override
  State<BreathCapacityTestScreen> createState() => _BreathCapacityTestScreenState();
}

class _BreathCapacityTestScreenState extends State<BreathCapacityTestScreen> {
  final AudioService _audioService = AudioService();
  final HapticService _hapticService = HapticService();
  final ProgressionService _progressionService = ProgressionService();
  final UserRepository _userRepo = UserRepository();

  TestPhase _phase = TestPhase.intro;

  // Timers & counters
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  int _secondsElapsed = 0;
  int _centeringBreath = 1;
  bool _centeringInhale = true;
  double _measuredCht = 0.0;
  int _recommendedLevel = 1;
  LevelInfo? _recommendedLevelInfo;

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _audioService.stopAll();
    super.dispose();
  }

  void _startCentering() {
    setState(() {
      _phase = TestPhase.centering;
      _secondsElapsed = 0;
      _centeringBreath = 1;
      _centeringInhale = true;
    });

    _audioService.playBell(BellType.start);
    _hapticService.phaseTransitionPulse(1);

    // 3 centering cycles of 4s in, 4s out
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed % 4 == 0) {
          _centeringInhale = !_centeringInhale;
          _hapticService.phaseTransitionPulse(1);
          if (_centeringInhale) {
            _centeringBreath++;
            if (_centeringBreath > 3) {
              _startInhalePhase();
            }
          }
        }
      });
    });
  }

  void _startInhalePhase() {
    _ticker?.cancel();
    setState(() {
      _phase = TestPhase.inhale;
      _secondsElapsed = 0;
    });

    _audioService.playBell(BellType.transition);
    _hapticService.phaseTransitionPulse(1);

    // 4 seconds smooth inhale
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed >= 4) {
          _startHoldingPhase();
        }
      });
    });
  }

  void _startHoldingPhase() {
    _ticker?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    setState(() {
      _phase = TestPhase.holding;
      _secondsElapsed = 0;
    });

    _audioService.playBell(BellType.transition);
    _hapticService.completionPulse();

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  void _finishHoldAndEvaluate() async {
    _stopwatch.stop();
    _ticker?.cancel();
    _measuredCht = _stopwatch.elapsedMilliseconds / 1000.0;
    if (_measuredCht < 3.0) _measuredCht = 3.0; // Floor

    _audioService.playBell(BellType.end);
    _hapticService.completionPulse();

    // Determine apt level from Cht
    final level = _progressionService.calculateLevelFromCht(_measuredCht);
    final info = _progressionService.getLevelInfo(level);

    // Persist CHT benchmark
    await _userRepo.saveChtBenchmark(_measuredCht);

    setState(() {
      _phase = TestPhase.completed;
      _recommendedLevel = level;
      _recommendedLevelInfo = info;
    });
  }

  void _applyCalibratedLevel() async {
    await _progressionService.saveCalibratedLevel(_recommendedLevel);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sadhana calibrated! Level $_recommendedLevel (${_recommendedLevelInfo?.title}) is now your active rank.'),
        backgroundColor: AbhyasTheme.leaf,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Sopana Pariksha (Breath Test)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _buildPhaseContent(),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case TestPhase.intro:
        return _buildIntroView();
      case TestPhase.centering:
        return _buildCenteringView();
      case TestPhase.inhale:
        return _buildInhaleView();
      case TestPhase.holding:
        return _buildHoldingView();
      case TestPhase.completed:
        return _buildCompletedView();
    }
  }

  Widget _buildIntroView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.saffron.withValues(alpha: 0.15),
            border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.speed, color: AbhyasTheme.saffron, size: 54),
        ),
        const SizedBox(height: 24),
        const Text(
          'Find Your Apt Level & Ratio',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This 1-minute test measures your Comfortable Hold Time (CHT) to diagnose your lung capacity, vagal tone, and optimal Kumbhaka ratio.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AbhyasTheme.darkInkSoft, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AbhyasTheme.darkSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AbhyasTheme.line),
          ),
          child: Column(
            children: const [
              _RuleRow(icon: Icons.check_circle_outline, text: '3 calming breaths to steady your heart rate.'),
              SizedBox(height: 10),
              _RuleRow(icon: Icons.check_circle_outline, text: '1 deep, effortless inhalation.'),
              SizedBox(height: 10),
              _RuleRow(icon: Icons.check_circle_outline, text: 'Hold comfortably — release at the first urge to breathe.'),
              SizedBox(height: 10),
              _RuleRow(icon: Icons.shield_outlined, text: 'Never strain or gasp. Safety overrides everything.'),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AbhyasTheme.saffron,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _startCentering,
            child: const Text('Begin 1-Min Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCenteringView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'STAGE 1: CENTERING BREATHS',
          style: TextStyle(color: AbhyasTheme.sky, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          'Breath $_centeringBreath of 3: ${_centeringInhale ? "Inhale Gently" : "Exhale Slowly"}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 40),
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: _centeringInhale ? 220 : 160,
          height: _centeringInhale ? 220 : 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(color: AbhyasTheme.sky, width: 4),
            boxShadow: [
              BoxShadow(
                color: AbhyasTheme.sky.withValues(alpha: 0.25),
                blurRadius: 30,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _centeringInhale ? 'INHALE' : 'EXHALE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AbhyasTheme.sky),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Relax your shoulders, jaw, and belly.',
          style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInhaleView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'STAGE 2: DEEP INHALE',
          style: TextStyle(color: AbhyasTheme.saffron, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fill your lungs completely & effortlessly',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 40),
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(color: AbhyasTheme.saffron, width: 5),
            boxShadow: [
              BoxShadow(
                color: AbhyasTheme.saffron.withValues(alpha: 0.35),
                blurRadius: 30,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${4 - _secondsElapsed}s',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text('Get ready to hold gently...', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
      ],
    );
  }

  Widget _buildHoldingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'STAGE 3: COMFORTABLE HOLD',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hold gently without strain',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 40),
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AbhyasTheme.darkSurface,
            border: Border.all(color: Colors.amber, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_secondsElapsed}s',
                  style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w200, color: Colors.white),
                ),
                const Text(
                  'HOLDING',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Tap the button the moment you feel the first urge to exhale.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.air, size: 24),
            label: const Text('Release Breath Now (Rechaka)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _finishHoldAndEvaluate,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final info = _recommendedLevelInfo;
    final safeCap = (_measuredCht * 0.60).round();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AbhyasTheme.leaf.withValues(alpha: 0.15),
              border: Border.all(color: AbhyasTheme.leaf, width: 2),
            ),
            child: const Icon(Icons.verified, color: AbhyasTheme.leaf, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pariksha Complete',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Comfortable Hold Time: ${_measuredCht.toStringAsFixed(1)}s',
            style: const TextStyle(fontSize: 16, color: AbhyasTheme.saffron, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Diagnosis Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECOMMENDED LEVEL', style: TextStyle(color: AbhyasTheme.sky, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Level $_recommendedLevel', style: const TextStyle(color: AbhyasTheme.saffron, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info?.title ?? 'Sopana Level',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  info?.subtitle ?? '',
                  style: const TextStyle(fontSize: 13, color: AbhyasTheme.darkInkSoft),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AbhyasTheme.line),
                const SizedBox(height: 14),
                _MetricRow(label: 'Optimal Breath Ratio', value: info?.ratioDescription ?? '1:0:1:0'),
                const SizedBox(height: 8),
                _MetricRow(label: 'Safe Hold Cap (60% CHT)', value: '${safeCap}s max hold'),
                const SizedBox(height: 8),
                _MetricRow(label: 'Kapalbhati Pace', value: '${info?.kapalbhatiStrokes ?? 30} strokes/round'),
                const SizedBox(height: 8),
                _MetricRow(label: 'Mudras & Bandhas', value: info?.unlockedSeals.join(", ") ?? 'Gyan Mudra'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Apply Level Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AbhyasTheme.saffron,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _applyCalibratedLevel,
              child: Text(
                'Set My Active Rank to Level $_recommendedLevel',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Customize in Planner
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AbhyasTheme.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CycleComposerScreen()),
                );
              },
              child: const Text('Open Routine Planner with this Ratio'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AbhyasTheme.saffron),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
