import 'package:flutter/material.dart';
import '../../engine/player/yoga_nidra_player.dart';
import '../../core/audio_service.dart';

class YogaNidraScreen extends StatefulWidget {
  final int durationMinutes;

  const YogaNidraScreen({Key? key, required this.durationMinutes}) : super(key: key);

  @override
  _YogaNidraScreenState createState() => _YogaNidraScreenState();
}

class _YogaNidraScreenState extends State<YogaNidraScreen> {
  late YogaNidraPlayer _player;
  final AudioService _audioService = AudioService();
  int _secondsElapsed = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = YogaNidraPlayer(durationMinutes: widget.durationMinutes);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Yoga Nidra Session Complete.'))
    );
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _player.start(_onTick, _onComplete);
        // Play the guided Yoga Nidra audio track
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

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    final double progress = totalSeconds > 0 ? _secondsElapsed / totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        title: Text('Yoga Nidra'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 100, color: Colors.indigo.shade200),
            SizedBox(height: 40),
            Text(
              'Duration: ${widget.durationMinutes} min',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              _formatTime(_secondsElapsed),
              style: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w300),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 60),
            IconButton(
              iconSize: 80,
              color: Colors.white,
              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
              onPressed: _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}
