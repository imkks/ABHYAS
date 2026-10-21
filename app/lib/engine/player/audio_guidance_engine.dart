import 'player_engine.dart';

enum AudioGuidanceLevel {
  stage1Guided,      // Pre-flight instruction + 1-word cues + earcons + pulse
  stage2Cued,        // Phase name cue + earcons (no verbal counting)
  stage3SonicTimer,  // Harmonic earcons only, zero spoken voice
  stage4SelfLed,     // Start, halfway, and end bells only; silence during cycles
  stage5Independent, // Silent self-assessment mode
}

enum SoundPalette {
  singingBowl,
  templeBell,
  woodblock,
  fluteHarmonic,
}

enum AudioCueType {
  settlingStart,
  settlingTick,
  practiceStart,
  phaseTransition,
  pacingPulse,
  halfwayPoint,
  cycleComplete,
  sessionEnding,
  integrationStart,
  integrationComplete,
  emergencyGrounding,
}

enum HandsFreeAction {
  togglePlayPause,
  nextPhaseOrCycle,
  emergencyStop,
  repeatCue,
}

class AudioCueEvent {
  final AudioCueType type;
  final PracticePhase? phase;
  final String? spokenText;
  final String? voiceAssetIdentifier;
  final String soundIdentifier;
  final bool triggerHaptic;

  const AudioCueEvent({
    required this.type,
    this.phase,
    this.spokenText,
    this.voiceAssetIdentifier,
    required this.soundIdentifier,
    this.triggerHaptic = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioCueEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          phase == other.phase &&
          spokenText == other.spokenText &&
          voiceAssetIdentifier == other.voiceAssetIdentifier &&
          soundIdentifier == other.soundIdentifier &&
          triggerHaptic == other.triggerHaptic;

  @override
  int get hashCode =>
      type.hashCode ^
      phase.hashCode ^
      spokenText.hashCode ^
      voiceAssetIdentifier.hashCode ^
      soundIdentifier.hashCode ^
      triggerHaptic.hashCode;

  @override
  String toString() =>
      'AudioCueEvent(type: $type, phase: $phase, spoken: "$spokenText", voiceAsset: "$voiceAssetIdentifier", sound: "$soundIdentifier")';
}

/// Pure Dart audio guidance planner and state coordinator.
/// Keeps practice hands-free with minimal disturbance and handles progressive weaning.
/// All audio is direct pre-rendered audio (no runtime TTS latency or synthetic speech).
class AudioGuidanceEngine {
  final SoundPalette palette;
  final int weaningStage; // 1 to 5
  final int settlingDurationSeconds;
  final int integrationDurationSeconds;

  int _settlingSecondsLeft = 0;
  int _integrationSecondsLeft = 0;
  bool _isSettling = false;
  bool _isIntegrating = false;

  AudioGuidanceEngine({
    this.palette = SoundPalette.singingBowl,
    this.weaningStage = 1,
    this.settlingDurationSeconds = 10,
    this.integrationDurationSeconds = 60,
  }) {
    _settlingSecondsLeft = settlingDurationSeconds;
    _integrationSecondsLeft = integrationDurationSeconds;
  }

  bool get isSettling => _isSettling;
  bool get isIntegrating => _isIntegrating;
  int get settlingSecondsLeft => _settlingSecondsLeft;
  int get integrationSecondsLeft => _integrationSecondsLeft;

  AudioGuidanceLevel get guidanceLevel {
    switch (weaningStage) {
      case 1:
        return AudioGuidanceLevel.stage1Guided;
      case 2:
        return AudioGuidanceLevel.stage2Cued;
      case 3:
        return AudioGuidanceLevel.stage3SonicTimer;
      case 4:
        return AudioGuidanceLevel.stage4SelfLed;
      case 5:
      default:
        return AudioGuidanceLevel.stage5Independent;
    }
  }

  /// Starts the pre-practice hands-free settling countdown.
  /// Gives practitioner time to assume posture, place phone away, and close eyes.
  AudioCueEvent startSettlingBuffer() {
    _isSettling = true;
    _settlingSecondsLeft = settlingDurationSeconds;
    _isIntegrating = false;

    String? spokenText;
    String? voiceAsset;
    if (weaningStage <= 2) {
      spokenText = 'Take your seat, close your eyes, and settle into posture.';
      voiceAsset = 'assets/audio/voice/voice_settle.wav';
    }

    return AudioCueEvent(
      type: AudioCueType.settlingStart,
      spokenText: spokenText,
      voiceAssetIdentifier: voiceAsset,
      soundIdentifier: _getPaletteSoundKey('settling_bell'),
      triggerHaptic: true,
    );
  }

  /// Ticks the settling countdown by 1 second.
  /// Returns an AudioCueEvent when a countdown cue occurs, or null if silent.
  AudioCueEvent? tickSettlingBuffer() {
    if (!_isSettling) return null;
    if (_settlingSecondsLeft > 0) {
      _settlingSecondsLeft--;
    }

    if (_settlingSecondsLeft == 0) {
      _isSettling = false;
      return AudioCueEvent(
        type: AudioCueType.practiceStart,
        spokenText: (weaningStage <= 2) ? 'Begin.' : null,
        voiceAssetIdentifier: (weaningStage <= 2) ? 'assets/audio/voice/voice_begin.wav' : null,
        soundIdentifier: _getPaletteSoundKey('practice_start_gong'),
        triggerHaptic: true,
      );
    }

    // Audible/haptic countdown pulse during last 3 seconds
    if (_settlingSecondsLeft <= 3 && _settlingSecondsLeft > 0) {
      return AudioCueEvent(
        type: AudioCueType.settlingTick,
        spokenText: (weaningStage == 1) ? '$_settlingSecondsLeft' : null,
        voiceAssetIdentifier: (weaningStage == 1) ? 'assets/audio/voice/voice_count_$_settlingSecondsLeft.wav' : null,
        soundIdentifier: _getPaletteSoundKey('tick_soft'),
        triggerHaptic: true,
      );
    }

    return null;
  }

  /// Generates the minimal audio/sonic cue for a practice phase transition
  /// respecting the weaning stage.
  AudioCueEvent getCueForPhaseTransition({
    required PracticePhase phase,
    required int cycleNumber,
  }) {
    final level = guidanceLevel;
    String soundKey;
    String? spokenText;
    String? voiceAsset;

    switch (phase) {
      case PracticePhase.puraka:
        soundKey = _getPaletteSoundKey('puraka_inhale');
        if (level == AudioGuidanceLevel.stage1Guided ||
            level == AudioGuidanceLevel.stage2Cued) {
          spokenText = 'Inhale';
          voiceAsset = 'assets/audio/voice/voice_puraka.wav';
        }
        break;

      case PracticePhase.antarKumbhaka:
        soundKey = _getPaletteSoundKey('kumbhaka_hold');
        if (level == AudioGuidanceLevel.stage1Guided ||
            level == AudioGuidanceLevel.stage2Cued) {
          spokenText = 'Hold';
          voiceAsset = 'assets/audio/voice/voice_kumbhaka.wav';
        }
        break;

      case PracticePhase.rechaka:
        soundKey = _getPaletteSoundKey('rechaka_exhale');
        if (level == AudioGuidanceLevel.stage1Guided ||
            level == AudioGuidanceLevel.stage2Cued) {
          spokenText = 'Exhale';
          voiceAsset = 'assets/audio/voice/voice_rechaka.wav';
        }
        break;

      case PracticePhase.bahyaKumbhaka:
        soundKey = _getPaletteSoundKey('bahya_pause');
        if (level == AudioGuidanceLevel.stage1Guided ||
            level == AudioGuidanceLevel.stage2Cued) {
          spokenText = 'Suspend';
          voiceAsset = 'assets/audio/voice/voice_bahya.wav';
        }
        break;

      case PracticePhase.naturalBreath:
        soundKey = _getPaletteSoundKey('grounding_bell');
        spokenText = 'Ease your breath. Rest naturally.';
        voiceAsset = 'assets/audio/voice/voice_rest.wav';
        break;
    }

    // In Stage 3 (Sonic Timer), voice is completely muted; only earcon sounds play.
    // In Stage 4 & 5, transition earcons during cycles are also silenced (boundary bells only).
    if (level == AudioGuidanceLevel.stage3SonicTimer) {
      spokenText = null;
      voiceAsset = null;
    } else if (level == AudioGuidanceLevel.stage4SelfLed ||
               level == AudioGuidanceLevel.stage5Independent) {
      spokenText = null;
      voiceAsset = null;
      soundKey = 'silence';
    }

    return AudioCueEvent(
      type: AudioCueType.phaseTransition,
      phase: phase,
      spokenText: spokenText,
      voiceAssetIdentifier: voiceAsset,
      soundIdentifier: soundKey,
      triggerHaptic: level != AudioGuidanceLevel.stage5Independent,
    );
  }

  /// Emergency exit audio cue (AC-9 return to natural breath).
  /// Delivers a calming, grounding sound with minimal spoken reassurance.
  AudioCueEvent getEmergencyGroundingCue() {
    _isSettling = false;
    _isIntegrating = false;

    return AudioCueEvent(
      type: AudioCueType.emergencyGrounding,
      phase: PracticePhase.naturalBreath,
      spokenText: 'Ease your breath. Rest naturally.',
      voiceAssetIdentifier: 'assets/audio/voice/voice_rest.wav',
      soundIdentifier: _getPaletteSoundKey('grounding_bell'),
      triggerHaptic: true,
    );
  }

  /// Starts post-practice silent integration period.
  AudioCueEvent startIntegrationBuffer() {
    _isIntegrating = true;
    _isSettling = false;
    _integrationSecondsLeft = integrationDurationSeconds;

    return AudioCueEvent(
      type: AudioCueType.integrationStart,
      spokenText: (weaningStage <= 2)
          ? 'Practice complete. Remain still and observe the breath.'
          : null,
      voiceAssetIdentifier: (weaningStage <= 2)
          ? 'assets/audio/voice/voice_complete.wav'
          : null,
      soundIdentifier: _getPaletteSoundKey('session_complete_3bowls'),
      triggerHaptic: true,
    );
  }

  /// Ticks the post-session integration buffer.
  AudioCueEvent? tickIntegrationBuffer() {
    if (!_isIntegrating) return null;
    if (_integrationSecondsLeft > 0) {
      _integrationSecondsLeft--;
    }

    if (_integrationSecondsLeft == 0) {
      _isIntegrating = false;
      return AudioCueEvent(
        type: AudioCueType.integrationComplete,
        spokenText: 'When you are ready, gently open your eyes.',
        voiceAssetIdentifier: 'assets/audio/voice/voice_open_eyes.wav',
        soundIdentifier: _getPaletteSoundKey('shanti_chime'),
        triggerHaptic: true,
      );
    }

    return null;
  }

  /// Maps earcon asset names based on chosen sound palette.
  String _getPaletteSoundKey(String baseName) {
    final prefix = palette.name;
    return 'assets/audio/${prefix}_$baseName.wav';
  }
}
