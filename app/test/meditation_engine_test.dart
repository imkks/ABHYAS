import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/engine/meditation/meditation_engine.dart';
import 'package:abhyas/engine/player/audio_guidance_engine.dart';

void main() {
  group('Progressive 3-Stage Naam Japa Engine Tests', () {
    test('Transitions from Vaikhari -> Upamshu -> Manasika -> Laya based on time', () {
      final engine = ProgressiveJapaEngine(
        totalDurationSeconds: 300, // 5 mins total
        vaikhariRatio: 0.33,       // ~99s
        upamshuRatio: 0.33,        // ~99s
        manasikaRatio: 0.34,       // ~102s
      );

      final startCue = engine.start();
      expect(engine.currentStage, equals(JapaStage.vaikhari));
      expect(startCue.type, equals(AudioCueType.practiceStart));
      expect(startCue.voiceAssetIdentifier, contains('voice_japa_vaikhari.wav'));

      // Fast forward past vaikhari duration (99s)
      AudioCueEvent? cue;
      for (int s = 1; s <= 100; s++) {
        final tickCue = engine.tickSecond(s);
        if (tickCue != null) cue = tickCue;
      }
      expect(engine.currentStage, equals(JapaStage.upamshu));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_upamshu.wav'));

      // Fast forward past upamshu duration
      for (int s = 101; s <= 200; s++) {
        final tickCue = engine.tickSecond(s);
        if (tickCue != null) cue = tickCue;
      }
      expect(engine.currentStage, equals(JapaStage.manasika));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_manasika.wav'));

      // Fast forward past manasika duration -> transitions to Laya (stillness)
      for (int s = 201; s <= 305; s++) {
        final tickCue = engine.tickSecond(s);
        if (tickCue != null) cue = tickCue;
      }
      expect(engine.currentStage, equals(JapaStage.laya));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_laya.wav'));

      // Fast forward past 60s of Laya -> completes session
      for (int s = 306; s <= 366; s++) {
        final tickCue = engine.tickSecond(s);
        if (tickCue != null) cue = tickCue;
      }
      expect(engine.currentStage, equals(JapaStage.complete));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_open_eyes.wav'));
    });

    test('Count-based Japa advances stages upon reaching target bead counts', () {
      final engine = ProgressiveJapaEngine(
        totalTargetBeads: 108,
        isCountBased: true,
        vaikhariRatio: 0.333, // 36 beads
        upamshuRatio: 0.333,  // 36 beads
        manasikaRatio: 0.334, // 36 beads
      );

      engine.start();
      expect(engine.currentStage, equals(JapaStage.vaikhari));

      // 36 beads in Vaikhari -> transitions to Upamshu
      AudioCueEvent? cue;
      for (int b = 1; b <= 36; b++) {
        final beadCue = engine.advanceBead(b);
        if (beadCue != null) cue = beadCue;
      }
      expect(engine.currentStage, equals(JapaStage.upamshu));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_upamshu.wav'));

      // 36 beads in Upamshu (total 72) -> transitions to Manasika
      for (int b = 37; b <= 72; b++) {
        final beadCue = engine.advanceBead(b);
        if (beadCue != null) cue = beadCue;
      }
      expect(engine.currentStage, equals(JapaStage.manasika));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_manasika.wav'));

      // Completing all 108 beads -> transitions to Laya Stillness
      for (int b = 73; b <= 108; b++) {
        final beadCue = engine.advanceBead(b);
        if (beadCue != null) cue = beadCue;
      }
      expect(engine.currentStage, equals(JapaStage.laya));
      expect(cue, isNotNull);
      expect(cue!.voiceAssetIdentifier, contains('voice_japa_laya.wav'));
    });
  });

  group('Breath Awareness (Prana Dharana) Engine Tests', () {
    test('Provides gentle spaced reminders without rushing', () {
      final engine = PranaDharanaEngine(
        durationMinutes: 10,
        intervalReminderSeconds: 180, // 3 mins
      );

      final startCue = engine.start();
      expect(startCue.voiceAssetIdentifier, contains('voice_breath_intro.wav'));
      expect(engine.isComplete, isFalse);

      // Between 0 and 179s, silence is preserved (no reminders)
      expect(engine.tickSecond(60), isNull);
      expect(engine.tickSecond(120), isNull);

      // At 180s (3 mins), first spaced reminder fires
      final reminder1 = engine.tickSecond(180);
      expect(reminder1, isNotNull);
      expect(reminder1!.voiceAssetIdentifier, contains('voice_breath_nostril.wav'));

      // At 360s (6 mins), second reminder fires
      final reminder2 = engine.tickSecond(360);
      expect(reminder2, isNotNull);
      expect(reminder2!.voiceAssetIdentifier, contains('voice_breath_pause.wav'));

      // At 600s (10 mins), completion cue fires
      final completeCue = engine.tickSecond(600);
      expect(completeCue, isNotNull);
      expect(completeCue!.voiceAssetIdentifier, contains('voice_breath_complete.wav'));
      expect(engine.isComplete, isTrue);
    });
  });
}
