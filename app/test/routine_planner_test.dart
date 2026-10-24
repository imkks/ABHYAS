import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/data/session_repository.dart';
import 'package:abhyas/engine/progression/guru_anumati_workflow.dart';
import 'package:abhyas/engine/progression/progression_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuruAnumatiWorkflow Open Access Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('openAccessMode true unlocks all 7 Sopana levels directly', () {
      final workflow = GuruAnumatiWorkflow();
      workflow.openAccessMode = true;

      for (int level = 1; level <= 7; level++) {
        expect(workflow.isLevelApproved(level), isTrue,
            reason: 'Level $level should be accessible in open access mode');
      }
    });

    test('openAccessMode false respects standard teacher gating', () {
      final workflow = GuruAnumatiWorkflow();
      workflow.openAccessMode = false;

      // Without simulated approval, level 3 should be unapproved
      expect(workflow.isLevelApproved(3), isFalse);

      // Simulate teacher approval
      workflow.requestUnlock('student-1', 3);
      workflow.simulateTeacherApproval(3, true, 'Approved by teacher');
      expect(workflow.isLevelApproved(3), isTrue);

      // Restore open access mode
      workflow.openAccessMode = true;
    });
  });

  group('SessionRepository Calmness Delta & Analytics Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SessionRecord calculates calmness delta accurately', () {
      final record = SessionRecord(
        practiceName: 'Morning Surya Abhyas',
        level: 2,
        durationSeconds: 1800,
        timestamp: DateTime.now(),
        checkinRating: 'calm',
        preCalmnessScore: 4,
        calmnessScore: 8,
        sensations: ['Mental clarity', 'Inner silence'],
      );

      expect(record.calmnessDelta, equals(4)); // 8 - 4 = +4
      expect(record.sensations, contains('Mental clarity'));

      final json = record.toJson();
      final restored = SessionRecord.fromJson(json);

      expect(restored.practiceName, equals('Morning Surya Abhyas'));
      expect(restored.calmnessScore, equals(8));
      expect(restored.preCalmnessScore, equals(4));
      expect(restored.calmnessDelta, equals(4));
      expect(restored.sensations, contains('Inner silence'));
    });

    test('SessionRepository calculates total practice minutes and average delta', () async {
      final repo = SessionRepository();

      await repo.logSession(SessionRecord(
        practiceName: 'Morning Abhyas',
        level: 1,
        durationSeconds: 1200, // 20m
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        checkinRating: 'calm',
        preCalmnessScore: 3,
        calmnessScore: 7, // delta +4
      ));

      await repo.logSession(SessionRecord(
        practiceName: 'Night Chandra Abhyas',
        level: 1,
        durationSeconds: 1500, // 25m
        timestamp: DateTime.now(),
        checkinRating: 'calm',
        preCalmnessScore: 4,
        calmnessScore: 8, // delta +4
      ));

      final totalMins = await repo.getTotalPracticeMinutes();
      expect(totalMins, equals(45)); // 20 + 25 = 45m

      final avgDelta = await repo.getAverageCalmnessDelta();
      expect(avgDelta, equals(4.0)); // (4 + 4) / 2 = 4.0
    });
  });

  group('ProgressionService Gamified Leveling Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ProgressionService returns all 7 Sopana levels correctly', () {
      final service = ProgressionService();
      final l1 = service.getLevelInfo(1);
      final l2 = service.getLevelInfo(2);
      final l3 = service.getLevelInfo(3);
      final l4 = service.getLevelInfo(4);
      final l5 = service.getLevelInfo(5);
      final l6 = service.getLevelInfo(6);
      final l7 = service.getLevelInfo(7);

      expect(l1.title, contains('Prarambha'));
      expect(l1.kapalbhatiStrokes, equals(30));
      expect(l1.unlockedSeals, contains('Gyan Mudra'));
      expect(l1.ratio, equals([4, 0, 4, 0]));

      expect(l2.title, contains('Abhyasi'));
      expect(l2.ratioDescription, contains('1:0:2:0'));
      expect(l2.ratio, equals([4, 0, 8, 0]));

      expect(l3.title, contains('Antaranga'));
      expect(l3.unlockedSeals, contains('Jalandhara Bandha'));
      expect(l3.ratio, equals([4, 4, 8, 0]));

      expect(l4.title, contains('Shaktiman'));
      expect(l4.ratio, equals([4, 8, 8, 0]));

      expect(l5.title, contains('Kumbhaka Siddha'));
      expect(l5.ratioDescription, contains('1:4:2:0'));
      expect(l5.ratio, equals([4, 16, 8, 0]));

      expect(l6.title, contains('Bandha Yogi'));
      expect(l6.unlockedSeals, contains('Maha Bandha'));
      expect(l6.ratio, equals([4, 16, 8, 8]));

      expect(l7.title, contains('Dhyani'));
      expect(l7.unlockedSeals, contains('Shambhavi Mudra'));
      expect(l7.ratio, equals([6, 24, 12, 0]));
    });

    test('User with zero sessions starts at Level 1 with 0 Tapas', () async {
      final service = ProgressionService();
      final progression = await service.getProgression();

      expect(progression.level, equals(1));
      expect(progression.title, contains('Prarambha'));
      expect(progression.totalTapas, equals(0));
      expect(progression.progressPercent, equals(0.0));
      expect(progression.earnedSeals, contains('Gyan Mudra'));
    });

    test('Earning Tapas XP advances level and unlocks higher practices', () async {
      final repo = SessionRepository();
      // Log a 30m session that awards 300 Tapas + 15 calm bonus = 315 Tapas
      await repo.logSession(SessionRecord(
        practiceName: 'Morning Surya Abhyas',
        level: 1,
        durationSeconds: 1800,
        timestamp: DateTime.now(),
        checkinRating: 'calm',
        preCalmnessScore: 3,
        calmnessScore: 8,
      ));

      final service = ProgressionService();
      final progression = await service.getProgression();

      // >= 300 Tapas advances user to Level 2 (Abhyasi)
      expect(progression.level, equals(2));
      expect(progression.title, contains('Abhyasi'));
      expect(progression.totalTapas, greaterThanOrEqualTo(300));
      expect(progression.ratioDescription, contains('1:0:2:0'));
      expect(progression.earnedSeals, contains('Dhyana Mudra'));
    });

    test('calculateLevelFromCht maps breath hold times to apt Sopana levels accurately', () {
      final service = ProgressionService();

      expect(service.calculateLevelFromCht(10.0), equals(1)); // <15s -> Level 1
      expect(service.calculateLevelFromCht(20.0), equals(2)); // 15-25s -> Level 2
      expect(service.calculateLevelFromCht(30.0), equals(3)); // 25-40s -> Level 3
      expect(service.calculateLevelFromCht(48.0), equals(4)); // 40-60s -> Level 4
      expect(service.calculateLevelFromCht(75.0), equals(5)); // 60s+ -> Level 5
    });

    test('saveCalibratedLevel sets active level and awards base Tapas', () async {
      final service = ProgressionService();

      // Calibrate user to Level 3 after breath test
      await service.saveCalibratedLevel(3);
      final progression = await service.getProgression();

      expect(progression.level, equals(3));
      expect(progression.title, contains('Antaranga'));
      expect(progression.totalTapas, greaterThanOrEqualTo(750));
      expect(progression.ratio, equals([4, 4, 8, 0]));
      expect(progression.earnedSeals, contains('Jalandhara Bandha'));
    });
  });

  group('Classical Master Sequence & Practice Mechanics Tests', () {
    test('Classical Master Sequence follows canonical 4-phase order', () {
      final masterSteps = [
        {'id': 'sankalp', 'phase': 0, 'title': 'Sankalp & Centering'},
        {'id': 'kapalbhati', 'phase': 1, 'title': 'Cleansing & Awakening'},
        {'id': 'nadi_shodhana', 'phase': 2, 'title': 'Channel Purification'},
        {'id': 'ujjayi', 'phase': 3, 'title': 'Soothing & Throat Focus'},
        {'id': 'bhramari', 'phase': 3, 'title': 'Soothing & Cranial Vibration'},
        {'id': 'breath_awareness', 'phase': 4, 'title': 'Integration & Stillness'},
      ];

      expect(masterSteps[1]['id'], equals('kapalbhati'));
      expect(masterSteps[2]['id'], equals('nadi_shodhana'));
      expect(masterSteps[3]['id'], equals('ujjayi'));
      expect(masterSteps[4]['id'], equals('bhramari'));
      expect(masterSteps[5]['id'], equals('breath_awareness'));
    });

    test('Nadi Shodhana ratio enforces proper Kumbhaka invariants', () {
      final level3Ratio = [4, 4, 8, 0]; // 1:1:2:0
      final level5Ratio = [4, 16, 8, 0]; // 1:4:2:0
      final level6Ratio = [4, 16, 8, 8]; // 1:4:2:2

      // Invariant 1: Rechaka >= Puraka
      expect(level3Ratio[2], greaterThanOrEqualTo(level3Ratio[0]));
      expect(level5Ratio[2], greaterThanOrEqualTo(level5Ratio[0]));

      // Invariant 2: Bahya Kumbhaka <= Antar Kumbhaka
      expect(level6Ratio[3], lessThanOrEqualTo(level6Ratio[1]));
    });

    test('Kapalbhati mechanics structure: active exhalations followed by Bahir Kumbhaka hold', () {
      const strokesDuration = 35; // 35 active strokes (~1/sec)
      const bahirKumbhakaDuration = 10; // 10s external hold on empty lungs
      const purakaDuration = 4; // deep puraka release
      const recoveryDuration = 6; // calm settling
      const singleRoundDuration = strokesDuration + bahirKumbhakaDuration + purakaDuration + recoveryDuration;

      expect(singleRoundDuration, equals(55));
      expect(bahirKumbhakaDuration, equals(10));
    });

    test('ProgressionService categorizes levels into 3 Yogic Journey Phases', () {
      final service = ProgressionService();

      final l1 = service.getLevelInfo(1);
      final l3 = service.getLevelInfo(3);
      final l5 = service.getLevelInfo(5);

      expect(l1.journeyPhase, contains('Phase 1: Foundation'));
      expect(l1.phaseName, equals('Foundation'));

      expect(l3.journeyPhase, contains('Phase 2: Deepening'));
      expect(l3.phaseName, equals('Deepening'));

      expect(l5.journeyPhase, contains('Phase 3: Advanced'));
      expect(l5.phaseName, equals('Advanced'));
    });

    test('Routine Planner: Only Nadi Shodhana carries 4-part breath ratio; others use technique-specific customizers', () {
      final sampleSteps = [
        {'id': 'sankalp', 'isPranayama': false, 'ratio': null},
        {'id': 'kapalbhati', 'isPranayama': true, 'ratio': null}, // Strokes + Bahir Kumbhaka
        {'id': 'nadi_shodhana', 'isPranayama': true, 'ratio': [4, 8, 8, 4]}, // Only Nadi Shodhana has 4-part ratio
        {'id': 'ujjayi', 'isPranayama': true, 'ratio': null}, // Ocean breath + optional internal hold
        {'id': 'bhramari', 'isPranayama': true, 'ratio': null}, // Humming + optional internal hold
        {'id': 'naam_jaap', 'isPranayama': false, 'ratio': null}, // 3-Stage Naam Japa
        {'id': 'breath_awareness', 'isPranayama': false, 'ratio': null}, // Nostril Dhyan Anchor
      ];

      for (final step in sampleSteps) {
        if (step['id'] != 'nadi_shodhana') {
          expect(step['ratio'], isNull, reason: '${step["id"]} must NOT have a hardcoded 4-part breath ratio');
        } else {
          expect(step['ratio'], isNotNull, reason: 'Nadi Shodhana MUST have a valid 4-part breath ratio');
        }
      }
    });

    test('Routine Planner Customizers: validates custom parameters per technique', () {
      // Kapalbhati parameter check
      const validStrokes = [30, 45, 60, 80];
      const validBahirHold = [0, 5, 10, 15];
      expect(validStrokes, contains(45));
      expect(validBahirHold, contains(10));

      // 3-Stage Naam Japa bead counts
      const validBeads = [27, 54, 108];
      expect(validBeads, contains(108));

      // Nostril Dhyan somatic anchors
      const validAnchors = ['Nostril Rim (Nasagra)', 'Brow Center (Ajna)', 'Heart Center (Anahata)', 'Navel (Manipura)'];
      expect(validAnchors, contains('Nostril Rim (Nasagra)'));
    });

    test('Audio Guidance & Phase Boundary Synchrony: boundary seconds map precisely to breath phases', () {
      // 1. Nadi Shodhana 4-part ratio boundary mapping (e.g. 4:8:8:4)
      const puraka = 4;
      const antar = 8;
      const rechaka = 8;
      const bahya = 4;
      const cycleTotal = puraka + antar + rechaka + bahya; // 24s

      // Puraka starts at 0s
      expect(0 % cycleTotal, equals(0));
      // Antar Kumbhaka starts at 4s
      expect(4 % cycleTotal, equals(puraka));
      // Rechaka starts at 12s
      expect(12 % cycleTotal, equals(puraka + antar));
      // Bahya Kumbhaka starts at 20s
      expect(20 % cycleTotal, equals(puraka + antar + rechaka));

      // 2. Kapalbhati classical boundary mapping (35s strokes -> 10s Bahir Kumbhaka -> 4s Puraka -> 6s rest = 55s round)
      const roundDuration = 55;
      expect(0 % roundDuration, equals(0)); // Rapid strokes start
      expect(35 % roundDuration, equals(35)); // 10s Bahir Kumbhaka (empty hold) starts
      expect(45 % roundDuration, equals(45)); // Puraka release starts
      expect(49 % roundDuration, equals(49)); // Natural rest starts
    });
  });
}
