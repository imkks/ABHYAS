import '../player/audio_guidance_engine.dart';

enum JapaStage {
  vaikhari, // Audible / Spoken aloud
  upamshu,  // Whispered / Subtle lip movement
  manasika, // Silent mental repetition
  laya,     // Stillness / Absorption
  complete,
}

enum BreathAnchor {
  nostrils,         // Nasagra Drishti: Touch at nostril entrance & upper lip
  navel,            // Nabhi: Spontaneous rise and fall of the abdomen
  chest,            // Hridaya: Subtle chest expansion
  spontaneousPause, // Kevala Kumbhaka: Quiet space between breaths
}

/// Pure Dart state machine for Progressive 3-Stage Naam Japa Meditation.
/// Transitions through Vaikhari -> Upamshu -> Manasika -> Laya Stillness.
class ProgressiveJapaEngine {
  final int totalDurationSeconds;
  final int? totalTargetBeads;
  final bool isCountBased;

  final double vaikhariRatio;
  final double upamshuRatio;
  final double manasikaRatio;

  JapaStage _stage = JapaStage.vaikhari;
  int _secondsInCurrentStage = 0;
  int _beadsInCurrentStage = 0;

  ProgressiveJapaEngine({
    this.totalDurationSeconds = 900, // 15 mins default
    this.totalTargetBeads,
    this.isCountBased = false,
    this.vaikhariRatio = 0.33,
    this.upamshuRatio = 0.33,
    this.manasikaRatio = 0.34,
  });

  JapaStage get currentStage => _stage;

  String get stageName {
    switch (_stage) {
      case JapaStage.vaikhari:
        return 'Vaikhari (Audible Chanting)';
      case JapaStage.upamshu:
        return 'Upamshu (Whispered Chanting)';
      case JapaStage.manasika:
        return 'Manasika (Mental Silence)';
      case JapaStage.laya:
        return 'Laya (Silent Absorption)';
      case JapaStage.complete:
        return 'Completed';
    }
  }

  String get stageInstruction {
    switch (_stage) {
      case JapaStage.vaikhari:
        return 'Chant aloud with clear voice to capture the physical senses.';
      case JapaStage.upamshu:
        return 'Lower voice to a whisper. Move only lips and feel the subtle vibration.';
      case JapaStage.manasika:
        return 'Still the lips and tongue completely. Let the mantra resonate mentally.';
      case JapaStage.laya:
        return 'Release all repetition. Rest in the vibrating silence within.';
      case JapaStage.complete:
        return 'Practice complete. Carry the inner peace into your day.';
    }
  }

  /// Calculates duration in seconds for each stage
  int get vaikhariTargetSeconds => (totalDurationSeconds * vaikhariRatio).round();
  int get upamshuTargetSeconds => (totalDurationSeconds * upamshuRatio).round();
  int get manasikaTargetSeconds => (totalDurationSeconds * manasikaRatio).round();
  int get layaTargetSeconds => 60; // 60s stillness at end

  /// Calculates beads for each stage if count-based
  int get vaikhariTargetBeads => ((totalTargetBeads ?? 108) * vaikhariRatio).round();
  int get upamshuTargetBeads => ((totalTargetBeads ?? 108) * upamshuRatio).round();
  int get manasikaTargetBeads => (totalTargetBeads ?? 108) - vaikhariTargetBeads - upamshuTargetBeads;

  AudioCueEvent start() {
    _stage = JapaStage.vaikhari;
    _secondsInCurrentStage = 0;
    _beadsInCurrentStage = 0;

    return const AudioCueEvent(
      type: AudioCueType.practiceStart,
      spokenText: 'Begin chanting aloud with a clear voice.',
      voiceAssetIdentifier: 'assets/audio/voice/voice_japa_vaikhari.wav',
      soundIdentifier: 'assets/audio/singingBowl_practice_start_gong.wav',
      triggerHaptic: false,
    );
  }

  /// Ticks 1 second for time-based session.
  /// Returns AudioCueEvent when transitioning stages, or null during ongoing stage.
  AudioCueEvent? tickSecond(int totalElapsedSeconds) {
    if (_stage == JapaStage.complete) return null;
    _secondsInCurrentStage++;

    if (_stage == JapaStage.vaikhari && _secondsInCurrentStage >= vaikhariTargetSeconds) {
      return advanceToNextStage();
    } else if (_stage == JapaStage.upamshu && _secondsInCurrentStage >= upamshuTargetSeconds) {
      return advanceToNextStage();
    } else if (_stage == JapaStage.manasika && _secondsInCurrentStage >= manasikaTargetSeconds) {
      return advanceToNextStage();
    } else if (_stage == JapaStage.laya && _secondsInCurrentStage >= layaTargetSeconds) {
      _stage = JapaStage.complete;
      return const AudioCueEvent(
        type: AudioCueType.sessionEnding,
        spokenText: 'When you are ready, gently open your eyes.',
        voiceAssetIdentifier: 'assets/audio/voice/voice_open_eyes.wav',
        soundIdentifier: 'assets/audio/singingBowl_shanti_chime.wav',
        triggerHaptic: false,
      );
    }

    return null;
  }

  /// Advances bead count for count-based session.
  AudioCueEvent? advanceBead(int currentTotalBead) {
    if (!isCountBased || _stage == JapaStage.complete || _stage == JapaStage.laya) return null;
    _beadsInCurrentStage++;

    if (_stage == JapaStage.vaikhari && _beadsInCurrentStage >= vaikhariTargetBeads) {
      return advanceToNextStage();
    } else if (_stage == JapaStage.upamshu && _beadsInCurrentStage >= upamshuTargetBeads) {
      return advanceToNextStage();
    } else if (_stage == JapaStage.manasika && currentTotalBead >= (totalTargetBeads ?? 108)) {
      return advanceToNextStage();
    }

    return null;
  }

  /// Manually transitions to next stage (or triggered by timer/bead completion)
  AudioCueEvent advanceToNextStage() {
    _secondsInCurrentStage = 0;
    _beadsInCurrentStage = 0;

    switch (_stage) {
      case JapaStage.vaikhari:
        _stage = JapaStage.upamshu;
        return const AudioCueEvent(
          type: AudioCueType.phaseTransition,
          spokenText: 'Shift to Upamshu. Lower your voice to a gentle whisper, moving only your lips.',
          voiceAssetIdentifier: 'assets/audio/voice/voice_japa_upamshu.wav',
          soundIdentifier: 'assets/audio/singingBowl_kumbhaka_hold.wav',
          triggerHaptic: false,
        );

      case JapaStage.upamshu:
        _stage = JapaStage.manasika;
        return const AudioCueEvent(
          type: AudioCueType.phaseTransition,
          spokenText: 'Shift to Manasika. Still the lips and tongue. Allow the mantra to repeat silently in the mind.',
          voiceAssetIdentifier: 'assets/audio/voice/voice_japa_manasika.wav',
          soundIdentifier: 'assets/audio/singingBowl_puraka_inhale.wav',
          triggerHaptic: false,
        );

      case JapaStage.manasika:
        _stage = JapaStage.laya;
        return const AudioCueEvent(
          type: AudioCueType.sessionEnding,
          spokenText: 'Release all repetition. Rest in the vibrating silence.',
          voiceAssetIdentifier: 'assets/audio/voice/voice_japa_laya.wav',
          soundIdentifier: 'assets/audio/singingBowl_session_complete_3bowls.wav',
          triggerHaptic: false,
        );

      case JapaStage.laya:
      case JapaStage.complete:
        _stage = JapaStage.complete;
        return const AudioCueEvent(
          type: AudioCueType.integrationComplete,
          spokenText: 'When you are ready, gently open your eyes.',
          voiceAssetIdentifier: 'assets/audio/voice/voice_open_eyes.wav',
          soundIdentifier: 'assets/audio/singingBowl_shanti_chime.wav',
          triggerHaptic: false,
        );
    }
  }
}

/// Pure Dart state machine for Breath Awareness Meditation (Prana Dharana / Anapanasati).
/// Provides spaced gentle reminders without disturbing natural breathing.
class PranaDharanaEngine {
  final int durationMinutes;
  final BreathAnchor anchor;
  final int intervalReminderSeconds;

  int _lastReminderSecond = 0;
  int _reminderIndex = 0;
  bool _isComplete = false;

  PranaDharanaEngine({
    this.durationMinutes = 10,
    this.anchor = BreathAnchor.nostrils,
    this.intervalReminderSeconds = 180, // Remind every 3 mins
  });

  bool get isComplete => _isComplete;
  int get totalSeconds => durationMinutes * 60;

  AudioCueEvent start() {
    _lastReminderSecond = 0;
    _reminderIndex = 0;
    _isComplete = false;

    return const AudioCueEvent(
      type: AudioCueType.practiceStart,
      spokenText: 'Sit upright and ease the body. Allow the breath to flow naturally without any effort.',
      voiceAssetIdentifier: 'assets/audio/voice/voice_breath_intro.wav',
      soundIdentifier: 'assets/audio/singingBowl_practice_start_gong.wav',
      triggerHaptic: false,
    );
  }

  AudioCueEvent? tickSecond(int elapsedSeconds) {
    if (_isComplete) return null;

    if (elapsedSeconds >= totalSeconds) {
      _isComplete = true;
      return const AudioCueEvent(
        type: AudioCueType.sessionEnding,
        spokenText: 'Meditation complete. Gently bring awareness back to the physical body and open your eyes.',
        voiceAssetIdentifier: 'assets/audio/voice/voice_breath_complete.wav',
        soundIdentifier: 'assets/audio/singingBowl_session_complete_3bowls.wav',
        triggerHaptic: false,
      );
    }

    // Spaced reminders every interval (e.g. 3 mins, 6 mins, 9 mins)
    if (elapsedSeconds > 0 &&
        elapsedSeconds - _lastReminderSecond >= intervalReminderSeconds &&
        (totalSeconds - elapsedSeconds) > 60) {
      _lastReminderSecond = elapsedSeconds;
      _reminderIndex++;

      switch (_reminderIndex % 3) {
        case 1:
          return const AudioCueEvent(
            type: AudioCueType.phaseTransition,
            spokenText: 'Notice the cool touch of inhalation at the nostrils, and the warmth of exhalation.',
            voiceAssetIdentifier: 'assets/audio/voice/voice_breath_nostril.wav',
            soundIdentifier: 'assets/audio/singingBowl_kumbhaka_hold.wav',
            triggerHaptic: false,
          );
        case 2:
          return const AudioCueEvent(
            type: AudioCueType.phaseTransition,
            spokenText: 'Rest your attention in the quiet space between the breaths.',
            voiceAssetIdentifier: 'assets/audio/voice/voice_breath_pause.wav',
            soundIdentifier: 'assets/audio/singingBowl_puraka_inhale.wav',
            triggerHaptic: false,
          );
        case 0:
        default:
          return const AudioCueEvent(
            type: AudioCueType.phaseTransition,
            spokenText: 'If the mind has wandered, gently bring awareness back to the natural breath.',
            voiceAssetIdentifier: 'assets/audio/voice/voice_breath_return.wav',
            soundIdentifier: 'assets/audio/singingBowl_tick_soft.wav',
            triggerHaptic: false,
          );
      }
    }

    return null;
  }
}
