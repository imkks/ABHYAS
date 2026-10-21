import 'package:flutter/services.dart';
import '../../engine/player/audio_guidance_engine.dart';

typedef AudioPlaybackHandler = Future<void> Function(String soundPath, double volume);
typedef SpokenVoiceHandler = Future<void> Function(String text);

/// Service responsible for executing sonic earcons, spoken voice cues, and haptics.
/// Designed with abstraction to be resilient both on physical devices and in test environments.
class PracticeAudioService {
  static final PracticeAudioService _instance = PracticeAudioService._internal();
  factory PracticeAudioService() => _instance;
  PracticeAudioService._internal();

  bool isVoiceEnabled = true;
  bool isAudioTonesEnabled = true;
  bool isHapticsEnabled = true;
  double volume = 0.8;

  // Optional custom handlers (useful for unit testing or custom audio backends)
  AudioPlaybackHandler? customAudioPlayer;
  SpokenVoiceHandler? customVoiceSynthesizer;

  final List<AudioCueEvent> _eventHistory = [];
  List<AudioCueEvent> get eventHistory => List.unmodifiable(_eventHistory);

  void clearHistory() {
    _eventHistory.clear();
  }

  /// Dispatches an AudioCueEvent to the appropriate hardware channels
  Future<void> dispatchCue(AudioCueEvent cue) async {
    _eventHistory.add(cue);

    // 1. Trigger subtle haptics if enabled for hands-free sensory confirmation
    if (isHapticsEnabled && cue.triggerHaptic) {
      await _triggerHapticForCue(cue.type);
    }

    // 2. Play sonic earcon / bell / chime
    if (isAudioTonesEnabled && cue.soundIdentifier != 'silence') {
      await _playSound(cue.soundIdentifier);
    }

    // 3. Play spoken instruction if provided and not muted
    if (isVoiceEnabled && cue.spokenText != null && cue.spokenText!.isNotEmpty) {
      await _speak(cue.spokenText!);
    }
  }

  Future<void> _playSound(String soundIdentifier) async {
    if (customAudioPlayer != null) {
      await customAudioPlayer!(soundIdentifier, volume);
      return;
    }

    // Fallback: System sound or silence if asset audio is loading
    try {
      if (soundIdentifier.contains('tick')) {
        await SystemSound.play(SystemSoundType.click);
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      // Gracefully handle environments without system sound support (e.g. headless tests)
    }
  }

  Future<void> _speak(String text) async {
    if (customVoiceSynthesizer != null) {
      await customVoiceSynthesizer!(text);
      return;
    }
    // Default fallback: logged/handled via platform TTS when integrated
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
    } catch (_) {
      // In headless test environments, platform channels may be absent
    }
  }
}
