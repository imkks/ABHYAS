import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/data/session_repository.dart';
import 'package:abhyas/engine/progression/guru_anumati_workflow.dart';

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
}
