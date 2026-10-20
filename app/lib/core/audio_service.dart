import 'package:flutter/foundation.dart';

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
///
/// Phase 1 Implementation: Stub that logs actions via [debugPrint].
/// The full API contract is defined here so that integrating a real audio
/// backend (e.g. just_audio) requires only swapping the implementation
/// methods without changing any call sites.
///
/// Usage:
/// ```dart
/// final audio = AudioService();
/// await audio.init();
/// await audio.playBell(BellType.start);
/// ```
class AudioService {
  // Singleton pattern
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioServiceStatus _status = AudioServiceStatus.idle;
  double _volume = 1.0;
  String? _currentTrackPath;

  /// Current playback status.
  AudioServiceStatus get status => _status;

  /// Whether audio is currently playing.
  bool get isPlaying => _status == AudioServiceStatus.playing;

  /// The asset path of the currently loaded track, if any.
  String? get currentTrackPath => _currentTrackPath;

  /// Initialize the audio service and preload/prepare the audio system.
  ///
  /// Call this once during app startup (e.g. in main.dart).
  /// TODO(audio): Preload bell and tick audio assets when just_audio is added.
  Future<void> init() async {
    debugPrint('[AudioService] init() — audio system prepared (stub)');
  }

  /// Play a bell sound of the given [type].
  ///
  /// TODO(audio): Load and play from `assets/audio/bell_<type>.mp3`
  Future<void> playBell(BellType type) async {
    debugPrint('[AudioService] playBell(${type.name}) at volume $_volume');
    // TODO(audio): Implement with just_audio one-shot player
  }

  /// Play a matra tick sound.
  ///
  /// TODO(audio): Load and play from assets/audio/tick.mp3
  Future<void> playTick() async {
    debugPrint('[AudioService] playTick() at volume $_volume');
    // TODO(audio): Implement with just_audio one-shot player
  }

  /// Play a longer audio track (e.g. guided Yoga Nidra session or mantra).
  ///
  /// [assetPath] is the path to the audio asset (e.g. 'assets/audio/yoga_nidra_20min.mp3').
  /// [onComplete] is called when the track finishes playing naturally.
  ///
  /// TODO(audio): Implement with just_audio main player
  Future<void> playTrack(String assetPath, {Function? onComplete}) async {
    debugPrint('[AudioService] playTrack($assetPath) at volume $_volume');
    _currentTrackPath = assetPath;
    _status = AudioServiceStatus.playing;
    // TODO(audio): Set up just_audio player with asset, listen for completion
    // and invoke onComplete callback when done.
  }

  /// Pause the currently playing track.
  ///
  /// Has no effect if no track is playing.
  /// TODO(audio): Implement with just_audio pause
  Future<void> pauseTrack() async {
    if (_status != AudioServiceStatus.playing) return;
    debugPrint('[AudioService] pauseTrack()');
    _status = AudioServiceStatus.paused;
    // TODO(audio): Pause just_audio player
  }

  /// Resume the currently paused track.
  ///
  /// Has no effect if no track is paused.
  /// TODO(audio): Implement with just_audio resume
  Future<void> resumeTrack() async {
    if (_status != AudioServiceStatus.paused) return;
    debugPrint('[AudioService] resumeTrack()');
    _status = AudioServiceStatus.playing;
    // TODO(audio): Resume just_audio player
  }

  /// Stop all audio playback and reset state.
  ///
  /// TODO(audio): Stop and dispose just_audio players
  Future<void> stopAll() async {
    debugPrint('[AudioService] stopAll()');
    _status = AudioServiceStatus.idle;
    _currentTrackPath = null;
    // TODO(audio): Stop all just_audio players
  }

  /// Set the master volume for all audio playback.
  ///
  /// [volume] must be between 0.0 (silent) and 1.0 (full volume).
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    debugPrint('[AudioService] setVolume($_volume)');
    // TODO(audio): Apply volume to just_audio players
  }

  /// Current master volume level (0.0 to 1.0).
  double get volume => _volume;
}
