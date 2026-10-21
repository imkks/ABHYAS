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

      expect(l2.title, contains('Abhyasi'));
      expect(l2.ratioDescription, contains('1:0:2:0'));

      expect(l3.title, contains('Antaranga'));
      expect(l3.unlockedSeals, contains('Jalandhara Bandha'));

      expect(l5.title, contains('Kumbhaka Siddha'));
      expect(l5.ratioDescription, contains('1:4:2:0'));

      expect(l6.title, contains('Bandha Yogi'));
      expect(l6.unlockedSeals, contains('Maha Bandha'));

      expect(l7.title, contains('Dhyani'));
      expect(l7.unlockedSeals, contains('Shambhavi Mudra'));
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
  });
}
