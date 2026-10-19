import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/engine/progression/guru_anumati_workflow.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GuruAnumatiWorkflow Tests', () {
    test('Request unlock adds a pending request', () async {
      final workflow = GuruAnumatiWorkflow();
      await workflow.requestUnlock('student-1', 3);

      final requests = await workflow.getRequests();
      expect(requests.length, 1);
      expect(requests.first.requestedLevel, 3);
      expect(requests.first.status, UnlockStatus.pending);
    });

    test('Simulate teacher approval updates request status', () async {
      final workflow = GuruAnumatiWorkflow();
      await workflow.requestUnlock('student-1', 4);

      var requests = await workflow.getRequests();
      expect(requests.first.status, UnlockStatus.pending);

      await workflow.simulateTeacherApproval(4, true, 'Great progress');

      requests = await workflow.getRequests();
      expect(requests.first.status, UnlockStatus.approved);
      expect(requests.first.teacherNote, 'Great progress');
    });

    test('isLevelApproved returns true if approved', () async {
      final workflow = GuruAnumatiWorkflow();
      await workflow.requestUnlock('student-1', 5);

      expect(await workflow.isLevelApproved(5), false);

      await workflow.simulateTeacherApproval(5, true, 'Approved for Level 5');

      expect(await workflow.isLevelApproved(5), true);
    });

    test('isLevelApproved returns false if denied', () async {
      final workflow = GuruAnumatiWorkflow();
      await workflow.requestUnlock('student-1', 6);

      await workflow.simulateTeacherApproval(6, false, 'Needs more practice');

      expect(await workflow.isLevelApproved(6), false);
    });
  });
}
