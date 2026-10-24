import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../engine/player/player_engine.dart';

/// Types of bell sounds used for practice cues.
enum BellType {
  /// Played when a practice session begins.
  start,

  /// Played when a practice session ends.
  end,

  /// Played on breath phase transitions.
  transition,
}

/// Current status of the audio service.
enum AudioServiceStatus {
  /// No audio is playing.
  idle,

  /// Audio is actively playing.
  playing,

  /// Audio playback is paused.
  paused,
}

/// Singleton audio service providing a unified API for all app audio playback.
/// Supports both short one-shot cues and continuous long-form guided audio tracks (e.g. Yoga Nidra).
class AudioService {
  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _trackPlayer;
  AudioPlayer? _bellPlayer;
  bool _initialized = false;

  AudioServiceStatus _status = AudioServiceStatus.idle;
  double _volume = 1.0;
  String? _currentTrackPath;

  /// Current playback status.
  AudioServiceStatus get status => _status;

  /// Whether audio is currently playing.
  bool get isPlaying => _status == AudioServiceStatus.playing;

  /// The asset path of the currently loaded track, if any.
  String? get currentTrackPath => _currentTrackPath;

  /// Master volume level (0.0 to 1.0).
  double get volume => _volume;

  AudioPlayer? get trackPlayer => _trackPlayer;

  /// Initialize the audio players.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _trackPlayer = AudioPlayer();
      _bellPlayer = AudioPlayer();
      await _trackPlayer?.setVolume(_volume);
      await _bellPlayer?.setVolume(_volume);
    } catch (_) {}
    _initialized = true;
  }

  /// Play a calibrated bell cue.
  Future<void> playBell(BellType type) async {
    try {
      if (!_initialized) await init();
      String asset;
      switch (type) {
        case BellType.start:
          asset = 'audio/singingBowl_practice_start_gong.wav';
          break;
        case BellType.end:
          asset = 'audio/singingBowl_session_complete_3bowls.wav';
          break;
        case BellType.transition:
          asset = 'audio/singingBowl_kumbhaka_hold.wav';
          break;
      }
      if (_bellPlayer != null) {
        await _bellPlayer!.stop();
        await _bellPlayer!.play(AssetSource(asset));
      }
    } catch (_) {}
  }

  /// Play a phase-specific harmonic Singing Bowl cue (Puraka, Kumbhaka, Rechaka, Bahya)
  Future<void> playPhaseCue(PracticePhase phase) async {
    try {
      if (!_initialized) await init();
      String asset;
      switch (phase) {
        case PracticePhase.puraka:
          asset = 'audio/singingBowl_puraka_inhale.wav';
          break;
        case PracticePhase.antarKumbhaka:
          asset = 'audio/singingBowl_kumbhaka_hold.wav';
          break;
        case PracticePhase.rechaka:
          asset = 'audio/singingBowl_rechaka_exhale.wav';
          break;
        case PracticePhase.bahyaKumbhaka:
          asset = 'audio/singingBowl_bahya_pause.wav';
          break;
        case PracticePhase.naturalBreath:
          asset = 'audio/singingBowl_grounding_bell.wav';
          break;
      }
      if (_bellPlayer != null) {
        await _bellPlayer!.stop();
        await _bellPlayer!.play(AssetSource(asset));
      }
    } catch (_) {}
  }

  /// Play a subtle click/tick sound using zero-latency system click so it never cuts off singing bowls
  Future<void> playTick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Play a longer continuous audio track (e.g. guided Yoga Nidra session or mantra).
  ///
  /// [assetPath] is the path to the audio asset (e.g. 'assets/audio/yoga_nidra_20min.mp3').
  /// [onComplete] is called when the track finishes playing naturally.
  Future<void> playTrack(String assetPath, {Function? onComplete}) async {
    _currentTrackPath = assetPath;
    _status = AudioServiceStatus.playing;

    try {
      if (!_initialized) await init();
      String clean = assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
      if (_trackPlayer != null) {
        await _trackPlayer!.stop();
        _trackPlayer!.onPlayerComplete.listen((_) {
          _status = AudioServiceStatus.idle;
          if (onComplete != null) onComplete();
        });

        try {
          await _trackPlayer!.play(AssetSource(clean));
        } catch (_) {
          if (clean.endsWith('.mp3')) {
            final wavAlt = clean.replaceAll('.mp3', '.wav');
            await _trackPlayer!.play(AssetSource(wavAlt));
          } else if (clean.endsWith('.wav')) {
            final mp3Alt = clean.replaceAll('.wav', '.mp3');
            await _trackPlayer!.play(AssetSource(mp3Alt));
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioService] Note: Audio asset $assetPath not yet found. Timer active: $e');
    }
  }

  /// Pause the currently playing track.
  Future<void> pauseTrack() async {
    if (_status != AudioServiceStatus.playing) return;
    try {
      await _trackPlayer?.pause();
      _status = AudioServiceStatus.paused;
    } catch (_) {}
  }

  /// Resume the currently paused track.
  Future<void> resumeTrack() async {
    if (_status != AudioServiceStatus.paused) return;
    try {
      await _trackPlayer?.resume();
      _status = AudioServiceStatus.playing;
    } catch (_) {}
  }

  /// Seek to a specific timestamp in the track.
  Future<void> seek(Duration position) async {
    try {
      await _trackPlayer?.seek(position);
    } catch (_) {}
  }

  /// Stop all audio playback and reset state.
  Future<void> stopAll() async {
    _status = AudioServiceStatus.idle;
    _currentTrackPath = null;
    try {
      await _trackPlayer?.stop();
      await _bellPlayer?.stop();
    } catch (_) {}
  }

  /// Set the master volume for all audio playback (0.0 to 1.0).
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    try {
      _trackPlayer?.setVolume(_volume);
      _bellPlayer?.setVolume(_volume);
    } catch (_) {}
  }
}
