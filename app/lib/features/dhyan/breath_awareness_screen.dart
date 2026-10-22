import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/audio/practice_audio_service.dart';
import '../../core/audio_service.dart';
import '../../core/theme.dart';
import '../../engine/meditation/meditation_engine.dart';
import '../../engine/player/audio_guidance_engine.dart';

class BreathAwarenessScreen extends StatefulWidget {
  final int initialMinutes;

  const BreathAwarenessScreen({super.key, this.initialMinutes = 10});

  @override
  State<BreathAwarenessScreen> createState() => _BreathAwarenessScreenState();
}

class _BreathAwarenessScreenState extends State<BreathAwarenessScreen> with SingleTickerProviderStateMixin {
  late PranaDharanaEngine _engine;
  final PracticeAudioService _audioService = PracticeAudioService();
  final AudioService _droneService = AudioService();

  late int _durationMinutes;
  BreathAnchor _selectedAnchor = BreathAnchor.nostrils;
  int _secondsElapsed = 0;
  bool _isPlaying = false;
  bool _isDroneEnabled = true;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.initialMinutes;
    _engine = PranaDharanaEngine(
      durationMinutes: _durationMinutes,
      anchor: _selectedAnchor,
    );
    _audioService.initAudio();
    _droneService.init();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  void _startPractice() {
    setState(() {
      _isPlaying = true;
      _secondsElapsed = 0;
      _engine = PranaDharanaEngine(
        durationMinutes: _durationMinutes,
        anchor: _selectedAnchor,
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
          if (cue.type == AudioCueType.sessionEnding) {
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
              if (cue.type == AudioCueType.sessionEnding) {
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
          title: const Text('Meditation Complete', style: TextStyle(color: Colors.tealAccent)),
          content: const Text(
            'You have completed your spontaneous breath awareness practice. Remain seated in stillness for a few quiet moments.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Conclude Session'),
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

  String _getAnchorLabel(BreathAnchor anchor) {
    switch (anchor) {
      case BreathAnchor.nostrils:
        return 'Nostril Touch & Upper Lip (Nasagra)';
      case BreathAnchor.navel:
        return 'Abdominal Rise & Fall (Nabhi)';
      case BreathAnchor.chest:
        return 'Heart & Chest Expansion (Hridaya)';
      case BreathAnchor.spontaneousPause:
        return 'Still Space Between Breaths (Kevala)';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _droneService.stopAll();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = _durationMinutes * 60;
    final double progress = totalSeconds > 0 ? (_secondsElapsed / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF071418), // Deep meditative teal night
      appBar: AppBar(
        title: const Text('Prana Dharana · Breath Awareness'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isDroneEnabled ? Icons.graphic_eq : Icons.volume_off,
              color: _isDroneEnabled ? Colors.tealAccent : Colors.white38,
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
      // Blind gestures for eyes-closed meditation
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _togglePlay,
        onLongPress: () {
          if (_isPlaying) {
            _completePractice();
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isPlaying && _secondsElapsed == 0) ...[
                  // Setup view before meditation begins
                  const Text(
                    'Natural Breath Witnessing',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No counting. No ratios. Simply witness the natural flow of breath.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Anchor Selector
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Somatic Breath Anchor:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 6),
                        DropdownButton<BreathAnchor>(
                          value: _selectedAnchor,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0F252C),
                          underline: Container(height: 1, color: Colors.tealAccent),
                          items: BreathAnchor.values.map((a) {
                            return DropdownMenuItem(
                              value: a,
                              child: Text(_getAnchorLabel(a), style: const TextStyle(color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (newAnchor) {
                            if (newAnchor != null) {
                              setState(() {
                                _selectedAnchor = newAnchor;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Duration Presets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [5, 10, 15, 20, 30].map((m) {
                      final isSel = _durationMinutes == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text('$m m'),
                          selected: isSel,
                          selectedColor: Colors.tealAccent,
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : Colors.white,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _durationMinutes = m;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                ],

                // Glowing organic breath circle animation
                ScaleTransition(
                  scale: _breathAnimation,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal.withOpacity(_isPlaying ? 0.25 : 0.12),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withOpacity(_isPlaying ? 0.2 : 0.05),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa, size: 40, color: Colors.tealAccent.shade100),
                          const SizedBox(height: 6),
                          Text(
                            _isPlaying ? 'WITNESSING' : 'READY',
                            style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Timer Display
                Text(
                  _formatTime(_secondsElapsed),
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w200),
                ),
                Text(
                  'Target: $_durationMinutes min · ${_getAnchorLabel(_selectedAnchor).split(" (").first}',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Linear Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    color: Colors.tealAccent,
                  ),
                ),

                const SizedBox(height: 36),

                // Play / Pause controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Pause' : (_secondsElapsed == 0 ? 'Begin Meditation' : 'Resume')),
                      onPressed: _togglePlay,
                    ),
                    if (_isPlaying || _secondsElapsed > 0) ...[
                      const SizedBox(width: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _completePractice,
                        child: const Text('Finish'),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Hands-Free Eyes-Closed Gestures:\nDouble-tap screen to Pause/Play · Long-press to finish',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
