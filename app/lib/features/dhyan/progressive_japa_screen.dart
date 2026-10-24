import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio/practice_audio_service.dart';
import '../../core/audio_service.dart';
import '../../core/theme.dart';
import '../../engine/meditation/meditation_engine.dart';
import '../../engine/player/audio_guidance_engine.dart';
import 'dhyan_screen.dart';

class ProgressiveJapaScreen extends StatefulWidget {
  final CustomMantra mantra;
  final int totalMinutes;
  final int? targetBeads;
  final bool isCountBased;

  const ProgressiveJapaScreen({
    super.key,
    required this.mantra,
    this.totalMinutes = 15,
    this.targetBeads = 108,
    this.isCountBased = false,
  });

  @override
  State<ProgressiveJapaScreen> createState() => _ProgressiveJapaScreenState();
}

class _ProgressiveJapaScreenState extends State<ProgressiveJapaScreen> {
  late ProgressiveJapaEngine _engine;
  final PracticeAudioService _audioService = PracticeAudioService();
  final AudioService _droneService = AudioService();

  int _secondsElapsed = 0;
  int _currentBeads = 0;
  bool _isPlaying = false;
  bool _isDroneEnabled = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _engine = ProgressiveJapaEngine(
      totalDurationSeconds: widget.totalMinutes * 60,
      totalTargetBeads: widget.targetBeads,
      isCountBased: widget.isCountBased,
    );
    _audioService.initAudio();
    _droneService.init();
  }

  void _startPractice() {
    setState(() {
      _isPlaying = true;
      _secondsElapsed = 0;
      _currentBeads = 0;
      _engine = ProgressiveJapaEngine(
        totalDurationSeconds: widget.totalMinutes * 60,
        totalTargetBeads: widget.targetBeads,
        isCountBased: widget.isCountBased,
      );
    });

    final startCue = _engine.start();
    _audioService.dispatchCue(startCue);

    if (_isDroneEnabled) {
      _droneService.playTrack('assets/audio/tanpura_drone.wav');
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        final cue = _engine.tickSecond(_secondsElapsed);
        if (cue != null) {
          _audioService.dispatchCue(cue);
          if (_engine.currentStage == JapaStage.complete) {
            _completePractice();
          }
        }
      });
    });
  }

  void _togglePlay() {
    if (!_isPlaying && _secondsElapsed == 0) {
      _startPractice();
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
            final cue = _engine.tickSecond(_secondsElapsed);
            if (cue != null) {
              _audioService.dispatchCue(cue);
              if (_engine.currentStage == JapaStage.complete) {
                _completePractice();
              }
            }
          });
        });
        if (_isDroneEnabled) {
          _droneService.resumeTrack();
        }
      } else {
        _timer?.cancel();
        _droneService.pauseTrack();
      }
    });
  }

  void _onBeadTapped() {
    if (!_isPlaying) {
      _togglePlay();
      return;
    }

    setState(() {
      _currentBeads++;
      final cue = _engine.advanceBead(_currentBeads);
      if (cue != null) {
        _audioService.dispatchCue(cue);
        if (_engine.currentStage == JapaStage.complete) {
          _completePractice();
        }
      }
    });
  }

  void _advanceToNextStageManual() {
    setState(() {
      final cue = _engine.advanceToNextStage();
      _audioService.dispatchCue(cue);
      if (_engine.currentStage == JapaStage.complete) {
        _completePractice();
      }
    });
  }

  void _completePractice() {
    _timer?.cancel();
    _droneService.stopAll();
    _audioService.stopAll();
    setState(() {
      _isPlaying = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AbhyasTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Japa Sadhana Complete', style: TextStyle(color: AbhyasTheme.saffron)),
          content: Text(
            'You have transitioned through the three sacred stages of sound vibration with ${widget.mantra.name}.\n\nRemain seated in stillness and absorb the silent blessing.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AbhyasTheme.saffron, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Conclude Japa'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getStageColor(JapaStage stage) {
    switch (stage) {
      case JapaStage.vaikhari:
        return Colors.orangeAccent;
      case JapaStage.upamshu:
        return Colors.amberAccent;
      case JapaStage.manasika:
        return Colors.deepPurpleAccent;
      case JapaStage.laya:
      case JapaStage.complete:
        return Colors.tealAccent;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _droneService.stopAll();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = widget.totalMinutes * 60;
    final double timeProgress = totalSeconds > 0 ? (_secondsElapsed / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final int targetBeads = widget.targetBeads ?? 108;
    final double countProgress = targetBeads > 0 ? (_currentBeads / targetBeads).clamp(0.0, 1.0) : 0.0;
    final double progress = widget.isCountBased ? countProgress : timeProgress;

    final activeColor = _getStageColor(_engine.currentStage);

    return Scaffold(
      backgroundColor: const Color(0xFF100B1C), // Deep sacred temple midnight
      appBar: AppBar(
        title: const Text('Progressive 3-Stage Naam Japa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isDroneEnabled ? Icons.graphic_eq : Icons.volume_off,
              color: _isDroneEnabled ? AbhyasTheme.saffron : Colors.white38,
            ),
            tooltip: 'Toggle Tanpura Ambient Drone',
            onPressed: () {
              setState(() {
                _isDroneEnabled = !_isDroneEnabled;
                if (!_isDroneEnabled) {
                  _droneService.stopAll();
                } else if (_isPlaying) {
                  _droneService.playTrack('assets/audio/tanpura_drone.wav');
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3-Stage Progress Timeline Header
              Row(
                children: [
                  _buildStageChip('1. Vaikhari (Audible)', JapaStage.vaikhari),
                  const SizedBox(width: 4),
                  _buildStageChip('2. Upamshu (Whisper)', JapaStage.upamshu),
                  const SizedBox(width: 4),
                  _buildStageChip('3. Manasika (Mental)', JapaStage.manasika),
                ],
              ),

              const SizedBox(height: 16),

              // Active Stage Instruction Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeColor.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      _engine.stageName.toUpperCase(),
                      style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _engine.stageInstruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Active Mantra Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.mantra.name,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.mantra.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (widget.mantra.meaning != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.mantra.meaning!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Digital Mala Interactive Bead Touch Disc
              GestureDetector(
                onTap: _onBeadTapped,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withOpacity(0.15),
                    border: Border.all(color: activeColor, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(_isPlaying ? 0.25 : 0.08),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isCountBased) ...[
                          Text(
                            '$_currentBeads',
                            style: TextStyle(color: activeColor, fontSize: 52, fontWeight: FontWeight.bold),
                          ),
                          Text('/ $targetBeads beads', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ] else ...[
                          Text(
                            _formatTime(_secondsElapsed),
                            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w200),
                          ),
                          Text(
                            'Target: ${widget.totalMinutes}m',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                widget.isCountBased ? 'Tap circle or bead to advance count' : 'Hands-free timed meditation',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),

              const SizedBox(height: 16),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: activeColor,
                ),
              ),

              const Spacer(),

              // Bottom Control Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(
                      _isPlaying ? 'Pause' : (_secondsElapsed == 0 ? 'Start Japa' : 'Resume'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _togglePlay,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.skip_next, size: 20),
                    label: const Text('Next Stage'),
                    onPressed: _advanceToNextStageManual,
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageChip(String title, JapaStage stage) {
    final bool isCurrent = _engine.currentStage == stage;
    final bool isPast = _engine.currentStage.index > stage.index;

    Color bg = Colors.white.withOpacity(0.05);
    Color text = Colors.white38;
    if (isCurrent) {
      bg = _getStageColor(stage).withOpacity(0.25);
      text = _getStageColor(stage);
    } else if (isPast) {
      bg = Colors.white10;
      text = Colors.white70;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isCurrent ? Border.all(color: _getStageColor(stage), width: 1.5) : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(color: text, fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
