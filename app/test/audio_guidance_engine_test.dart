import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/engine/player/player_engine.dart';
import 'package:abhyas/engine/player/audio_guidance_engine.dart';
import 'package:abhyas/core/audio/practice_audio_service.dart';

void main() {
  group('Audio Guidance Engine & Minimalist Sonic Planner Tests', () {
    test('Correct guidance levels are selected by weaning stage', () {
      expect(
        AudioGuidanceEngine(weaningStage: 1).guidanceLevel,
        equals(AudioGuidanceLevel.stage1Guided),
      );
      expect(
        AudioGuidanceEngine(weaningStage: 2).guidanceLevel,
        equals(AudioGuidanceLevel.stage2Cued),
      );
      expect(
        AudioGuidanceEngine(weaningStage: 3).guidanceLevel,
        equals(AudioGuidanceLevel.stage3SonicTimer),
      );
      expect(
        AudioGuidanceEngine(weaningStage: 4).guidanceLevel,
        equals(AudioGuidanceLevel.stage4SelfLed),
      );
      expect(
        AudioGuidanceEngine(weaningStage: 5).guidanceLevel,
        equals(AudioGuidanceLevel.stage5Independent),
      );
    });

    test('Settling buffer countdown emits correct cues and transitions to start', () {
      final engine = AudioGuidanceEngine(
        weaningStage: 1,
        settlingDurationSeconds: 4,
      );

      final startCue = engine.startSettlingBuffer();
      expect(engine.isSettling, isTrue);
      expect(engine.settlingSecondsLeft, equals(4));
      expect(startCue.type, equals(AudioCueType.settlingStart));
      expect(startCue.spokenText, contains('Take your seat'));
      expect(startCue.voiceAssetIdentifier, contains('voice_settle.wav'));

      // Tick 1: 4 -> 3 (should tick with count cue)
      final tick1 = engine.tickSettlingBuffer();
      expect(tick1, isNotNull);
      expect(tick1!.type, equals(AudioCueType.settlingTick));
      expect(tick1.spokenText, equals('3'));
      expect(tick1.voiceAssetIdentifier, contains('voice_count_3.wav'));

      // Tick 2: 3 -> 2
      final tick2 = engine.tickSettlingBuffer();
      expect(tick2, isNotNull);
      expect(tick2!.type, equals(AudioCueType.settlingTick));
      expect(tick2.spokenText, equals('2'));
      expect(tick2.voiceAssetIdentifier, contains('voice_count_2.wav'));

      // Tick 3: 2 -> 1
      final tick3 = engine.tickSettlingBuffer();
      expect(tick3, isNotNull);
      expect(tick3!.type, equals(AudioCueType.settlingTick));
      expect(tick3.spokenText, equals('1'));
      expect(tick3.voiceAssetIdentifier, contains('voice_count_1.wav'));

      // Tick 4: 1 -> 0 (Completes settling, starts practice)
      final startPracticeCue = engine.tickSettlingBuffer();
      expect(startPracticeCue, isNotNull);
      expect(startPracticeCue!.type, equals(AudioCueType.practiceStart));
      expect(startPracticeCue.voiceAssetIdentifier, contains('voice_begin.wav'));
      expect(engine.isSettling, isFalse);
    });

    test('Stage 1 (Guided) provides single-word cues and sound earcons', () {
      final engine = AudioGuidanceEngine(
        palette: SoundPalette.singingBowl,
        weaningStage: 1,
      );

      final puraka = engine.getCueForPhaseTransition(
        phase: PracticePhase.puraka,
        cycleNumber: 1,
      );
      expect(puraka.spokenText, equals('Inhale'));
      expect(puraka.voiceAssetIdentifier, contains('voice_puraka.wav'));
      expect(puraka.soundIdentifier, contains('puraka_inhale'));

      final hold = engine.getCueForPhaseTransition(
        phase: PracticePhase.antarKumbhaka,
        cycleNumber: 1,
      );
      expect(hold.spokenText, equals('Hold'));
      expect(hold.voiceAssetIdentifier, contains('voice_kumbhaka.wav'));
      expect(hold.soundIdentifier, contains('kumbhaka_hold'));

      final rechaka = engine.getCueForPhaseTransition(
        phase: PracticePhase.rechaka,
        cycleNumber: 1,
      );
      expect(rechaka.spokenText, equals('Exhale'));
      expect(rechaka.voiceAssetIdentifier, contains('voice_rechaka.wav'));
      expect(rechaka.soundIdentifier, contains('rechaka_exhale'));

      final pause = engine.getCueForPhaseTransition(
        phase: PracticePhase.bahyaKumbhaka,
        cycleNumber: 1,
      );
      expect(pause.spokenText, equals('Suspend'));
      expect(pause.voiceAssetIdentifier, contains('voice_bahya.wav'));
      expect(pause.soundIdentifier, contains('bahya_pause'));
    });

    test('Stage 3 (Sonic Timer) mutes spoken cues completely, leaving earcons', () {
      final engine = AudioGuidanceEngine(
        palette: SoundPalette.singingBowl,
        weaningStage: 3,
      );

      final puraka = engine.getCueForPhaseTransition(
        phase: PracticePhase.puraka,
        cycleNumber: 1,
      );
      expect(puraka.spokenText, isNull);
      expect(puraka.voiceAssetIdentifier, isNull);
      expect(puraka.soundIdentifier, contains('puraka_inhale'));

      final rechaka = engine.getCueForPhaseTransition(
        phase: PracticePhase.rechaka,
        cycleNumber: 1,
      );
      expect(rechaka.spokenText, isNull);
      expect(rechaka.voiceAssetIdentifier, isNull);
      expect(rechaka.soundIdentifier, contains('rechaka_exhale'));
    });

    test('Stage 4 & 5 (Self-Led / Independent) maintain uninterrupted silence during cycles', () {
      final engine = AudioGuidanceEngine(weaningStage: 4);

      final puraka = engine.getCueForPhaseTransition(
        phase: PracticePhase.puraka,
        cycleNumber: 1,
      );
      expect(puraka.spokenText, isNull);
      expect(puraka.soundIdentifier, equals('silence'));
    });

    test('Emergency Grounding (AC-9) produces reassuring, calming exit cue', () {
      final engine = AudioGuidanceEngine(weaningStage: 1);
      final emergencyCue = engine.getEmergencyGroundingCue();

      expect(emergencyCue.type, equals(AudioCueType.emergencyGrounding));
      expect(emergencyCue.phase, equals(PracticePhase.naturalBreath));
      expect(emergencyCue.spokenText, contains('Rest naturally'));
      expect(emergencyCue.voiceAssetIdentifier, contains('voice_rest.wav'));
      expect(emergencyCue.soundIdentifier, contains('grounding_bell'));
      expect(engine.isSettling, isFalse);
    });

    test('Post-session Integration buffer runs silently and chimes upon completion', () {
      final engine = AudioGuidanceEngine(
        weaningStage: 1,
        integrationDurationSeconds: 2,
      );

      final startCue = engine.startIntegrationBuffer();
      expect(engine.isIntegrating, isTrue);
      expect(startCue.type, equals(AudioCueType.integrationStart));
      expect(startCue.voiceAssetIdentifier, contains('voice_complete.wav'));

      // Tick 1: 2 -> 1 (silent)
      final tick1 = engine.tickIntegrationBuffer();
      expect(tick1, isNull);
      expect(engine.isIntegrating, isTrue);

      // Tick 2: 1 -> 0 (completion chime)
      final endCue = engine.tickIntegrationBuffer();
      expect(endCue, isNotNull);
      expect(endCue!.type, equals(AudioCueType.integrationComplete));
      expect(endCue.voiceAssetIdentifier, contains('voice_open_eyes.wav'));
      expect(endCue.soundIdentifier, contains('shanti_chime'));
      expect(engine.isIntegrating, isFalse);
    });

    test('PracticeAudioService records dispatched events in history', () async {
      final service = PracticeAudioService();
      service.clearHistory();

      final cue = AudioCueEvent(
        type: AudioCueType.phaseTransition,
        phase: PracticePhase.puraka,
        spokenText: 'Inhale',
        soundIdentifier: 'test_cue.wav',
      );

      await service.dispatchCue(cue);
      expect(service.eventHistory.length, equals(1));
      expect(service.eventHistory.first, equals(cue));
    });
  });
}
