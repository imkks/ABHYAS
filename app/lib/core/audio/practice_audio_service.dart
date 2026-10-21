import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../engine/player/audio_guidance_engine.dart';

typedef AudioPlaybackHandler = Future<void> Function(String soundPath, double volume);

/// Service responsible for playing direct pre-recorded audio assets (bells, bowls, and spoken cues).
/// Plays purely via AudioPlayer to eliminate text-to-speech conversion latency and synthetic robot voices.
class PracticeAudioService {
  static final PracticeAudioService _instance = PracticeAudioService._internal();
  factory PracticeAudioService() => _instance;
  PracticeAudioService._internal();

  AudioPlayer? _tonePlayer;
  AudioPlayer? _voicePlayer;
  bool _initialized = false;

  bool isVoiceEnabled = true;
  bool isAudioTonesEnabled = true;
  bool isHapticsEnabled = false; // Disabled by default to avoid vibration noise/ticking
  double volume = 0.85;

  // Optional custom handler (useful for unit testing or custom audio backends)
  AudioPlaybackHandler? customAudioPlayer;

  final List<AudioCueEvent> _eventHistory = [];
  List<AudioCueEvent> get eventHistory => List.unmodifiable(_eventHistory);

  void clearHistory() {
    _eventHistory.clear();
  }

  Future<void> initAudio() async {
    if (_initialized) return;
    try {
      _tonePlayer = AudioPlayer();
      await _tonePlayer?.setVolume(volume);

      _voicePlayer = AudioPlayer();
      await _voicePlayer?.setVolume(volume);
    } catch (_) {
      // In headless test environments, platform channels may be absent
    }

    _initialized = true;
  }

  /// Dispatches an AudioCueEvent to the audio players and haptics
  Future<void> dispatchCue(AudioCueEvent cue) async {
    _eventHistory.add(cue);

    // 1. Trigger subtle haptics if enabled for hands-free sensory confirmation
    if (isHapticsEnabled && cue.triggerHaptic) {
      try {
        await _triggerHapticForCue(cue.type);
      } catch (_) {}
    }

    // 2. Play sonic earcon / bell / chime
    if (isAudioTonesEnabled && cue.soundIdentifier != 'silence') {
      try {
        await _playSound(cue.soundIdentifier, isVoice: false);
      } catch (_) {}
    }

    // 3. Play spoken instruction audio file directly (no TTS latency!)
    if (isVoiceEnabled && cue.voiceAssetIdentifier != null) {
      try {
        await _playSound(cue.voiceAssetIdentifier!, isVoice: true);
      } catch (_) {}
    }
  }

  Future<void> _playSound(String soundIdentifier, {bool isVoice = false}) async {
    if (customAudioPlayer != null) {
      await customAudioPlayer!(soundIdentifier, volume);
      return;
    }

    try {
      if (!_initialized) {
        await initAudio();
      }

      String cleanPath = soundIdentifier;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring('assets/'.length);
      }

      final targetPlayer = isVoice ? _voicePlayer : _tonePlayer;
      if (targetPlayer != null) {
        await targetPlayer.stop();
        await targetPlayer.play(AssetSource(cleanPath));
        return;
      }
    } catch (_) {
      // Gracefully fall back if audio hardware or platform channel is unavailable
    }

    // Secondary fallback: System sounds
    try {
      if (soundIdentifier.contains('tick')) {
        await SystemSound.play(SystemSoundType.click);
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  Future<void> stopAll() async {
    try {
      await _tonePlayer?.stop();
    } catch (_) {}
    try {
      await _voicePlayer?.stop();
    } catch (_) {}
  }

  Future<void> _triggerHapticForCue(AudioCueType cueType) async {
    try {
      switch (cueType) {
        case AudioCueType.settlingTick:
        case AudioCueType.pacingPulse:
          await HapticFeedback.selectionClick();
          break;
        case AudioCueType.phaseTransition:
          await HapticFeedback.mediumImpact();
          break;
        case AudioCueType.emergencyGrounding:
        case AudioCueType.sessionEnding:
        case AudioCueType.integrationStart:
          await HapticFeedback.heavyImpact();
          break;
        default:
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {}
  }
}
