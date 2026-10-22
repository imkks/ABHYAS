import 'package:flutter/material.dart';
import '../../engine/player/yoga_nidra_player.dart';
import '../../core/audio_service.dart';

class YogaNidraScreen extends StatefulWidget {
  final int durationMinutes;

  const YogaNidraScreen({super.key, required this.durationMinutes});

  @override
  State<YogaNidraScreen> createState() => _YogaNidraScreenState();
}

class _YogaNidraScreenState extends State<YogaNidraScreen> {
  late YogaNidraPlayer _player;
  final AudioService _audioService = AudioService();
  int _secondsElapsed = 0;
  bool _isPlaying = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _player = YogaNidraPlayer(durationMinutes: widget.durationMinutes);
    _audioService.init();
  }

  void _onTick(int seconds) {
    setState(() {
      _secondsElapsed = seconds;
    });
  }

  void _onComplete() {
    setState(() {
      _isPlaying = false;
    });
    _audioService.stopAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yoga Nidra Session Complete. Hari Om Tat Sat.')),
      );
    }
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _player.start(_onTick, _onComplete);
        _audioService.playTrack(
          'assets/audio/yoga_nidra_${widget.durationMinutes}min.mp3',
          onComplete: _onComplete,
        );
      } else {
        _player.pause();
        _audioService.pauseTrack();
      }
    });
  }

  void _seekBy(int deltaSeconds) {
    final int totalSeconds = widget.durationMinutes * 60;
    final int newSeconds = (_secondsElapsed + deltaSeconds).clamp(0, totalSeconds);
    setState(() {
      _secondsElapsed = newSeconds;
    });
    _audioService.seek(Duration(seconds: newSeconds));
  }

  String _formatTime(int totalSeconds) {
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Classical 7-stage Yoga Nidra progression breakdown
  String _getCurrentStageName(double progress) {
    if (progress < 0.10) {
      return '1. Preparation & Stillness (Savasana)';
    } else if (progress < 0.20) {
      return '2. Sankalpa (Sacred Resolve)';
    } else if (progress < 0.50) {
      return '3. Rotation of Consciousness (Nyasa)';
    } else if (progress < 0.70) {
      return '4. Breath Awareness (Prana Dharana)';
    } else if (progress < 0.85) {
      return '5. Feeling Opposites (Heavy/Light, Warm/Cool)';
    } else if (progress < 0.95) {
      return '6. Chidakasha (Visualization)';
    } else {
      return '7. Externalization & Return';
    }
  }

  @override
  void dispose() {
    _player.stop();
    _audioService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalSeconds = widget.durationMinutes * 60;
    final double progress = totalSeconds > 0 ? (_secondsElapsed / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1424), // Deep meditative midnight blue
      appBar: AppBar(
        title: const Text('Yoga Nidra · Deep Guided Rest'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
            onPressed: () {
              setState(() {
                _volume = _volume > 0 ? 0.0 : 1.0;
                _audioService.setVolume(_volume);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Moon / Meditative Glow Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade900.withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigoAccent.withOpacity(_isPlaying ? 0.25 : 0.08),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.bedtime, size: 72, color: Colors.indigo.shade200),
                ),
              ),

              const SizedBox(height: 32),

              // Active Stage Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getCurrentStageName(progress),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 20),

              // Timer Display
              Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w200),
              ),
              Text(
                'Total: ${widget.durationMinutes} minutes',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // Interactive Scrubber Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: Colors.amberAccent,
                  activeTrackColor: Colors.amberAccent.shade100,
                  inactiveTrackColor: Colors.white12,
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _secondsElapsed.toDouble().clamp(0.0, totalSeconds.toDouble()),
                  min: 0.0,
                  max: totalSeconds.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      _secondsElapsed = val.toInt();
                    });
                    _audioService.seek(Duration(seconds: val.toInt()));
                  },
                ),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_secondsElapsed), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    Text('-${_formatTime(totalSeconds - _secondsElapsed)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Audio Controls (Rewind 10s, Play/Pause, Forward 10s)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    color: Colors.white70,
                    icon: const Icon(Icons.replay_10),
                    tooltip: 'Rewind 10s',
                    onPressed: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    iconSize: 76,
                    color: Colors.amberAccent,
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: _togglePlay,
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    iconSize: 40,
                    color: Colors.white70,
                    icon: const Icon(Icons.forward_10),
                    tooltip: 'Forward 10s',
                    onPressed: () => _seekBy(10),
                  ),
                ],
              ),

              const Spacer(),

              // Audio file location indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, size: 16, color: Colors.white38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Continuous Track: assets/audio/yoga_nidra_${widget.durationMinutes}min.mp3',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
