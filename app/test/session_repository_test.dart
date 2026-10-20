import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/data/session_repository.dart';

void main() {
  group('SessionRepository', () {
    late SessionRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = SessionRepository();
    });

    test('logSession and getSessions round-trip', () async {
      final session = SessionRecord(
        practiceName: 'anulom_vilom',
        level: 2,
        durationSeconds: 300,
        timestamp: DateTime(2026, 10, 19, 10, 0),
        checkinRating: 'calm',
        holdDurations: [4.0, 5.0, 4.5],
      );

      await repo.logSession(session);
      final sessions = await repo.getSessions();

      expect(sessions.length, 1);
      expect(sessions[0].practiceName, 'anulom_vilom');
      expect(sessions[0].level, 2);
      expect(sessions[0].durationSeconds, 300);
      expect(sessions[0].checkinRating, 'calm');
      expect(sessions[0].holdDurations, [4.0, 5.0, 4.5]);
    });

    test('getTapasCount increments correctly', () async {
      expect(await repo.getTapasCount(), 0);

      await repo.logSession(_makeSession(name: 'kapalbhati'));
      expect(await repo.getTapasCount(), 1);

      await repo.logSession(_makeSession(name: 'bhastrika'));
      expect(await repo.getTapasCount(), 2);
    });

    test('getComfortStreak counts consecutive calm from most recent', () async {
      // Log sessions in chronological order
      await repo.logSession(_makeSession(
        rating: 'agitated',
        time: DateTime(2026, 10, 1),
      ));
      await repo.logSession(_makeSession(
        rating: 'calm',
        time: DateTime(2026, 10, 2),
      ));
      await repo.logSession(_makeSession(
        rating: 'calm',
        time: DateTime(2026, 10, 3),
      ));
      await repo.logSession(_makeSession(
        rating: 'calm',
        time: DateTime(2026, 10, 4),
      ));

      // Last 3 are calm, so streak = 3
      expect(await repo.getComfortStreak(), 3);
    });

    test('getComfortStreak returns 0 when most recent is not calm', () async {
      await repo.logSession(_makeSession(
        rating: 'calm',
        time: DateTime(2026, 10, 1),
      ));
      await repo.logSession(_makeSession(
        rating: 'agitated',
        time: DateTime(2026, 10, 2),
      ));

      expect(await repo.getComfortStreak(), 0);
    });

    test('getComfortStreak returns 0 for empty sessions', () async {
      expect(await repo.getComfortStreak(), 0);
    });

    test('getAverageHold computes average across all sessions', () async {
      await repo.logSession(_makeSession(holds: [4.0, 6.0])); // avg 5.0
      await repo.logSession(_makeSession(holds: [10.0]));      // avg 10.0

      // Overall average: (4 + 6 + 10) / 3 = 6.666...
      final avg = await repo.getAverageHold();
      expect(avg, closeTo(6.667, 0.01));
    });

    test('getAverageHold returns 0.0 when no hold data', () async {
      await repo.logSession(_makeSession(holds: []));
      expect(await repo.getAverageHold(), 0.0);
    });

    test('getAverageHold returns 0.0 for empty sessions', () async {
      expect(await repo.getAverageHold(), 0.0);
    });
  });

  group('SessionRecord JSON', () {
    test('toJson and fromJson round-trip', () {
      final original = SessionRecord(
        practiceName: 'nadi_shodhana',
        level: 3,
        durationSeconds: 600,
        timestamp: DateTime(2026, 10, 19, 15, 30),
        checkinRating: 'neutral',
        holdDurations: [8.0, 9.5, 7.0],
      );

      final jsonMap = original.toJson();
      final restored = SessionRecord.fromJson(jsonMap);

      expect(restored.practiceName, original.practiceName);
      expect(restored.level, original.level);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.timestamp, original.timestamp);
      expect(restored.checkinRating, original.checkinRating);
      expect(restored.holdDurations, original.holdDurations);
    });
  });
}

/// Helper to create a SessionRecord with sensible defaults.
SessionRecord _makeSession({
  String name = 'test_practice',
  int level = 1,
  int duration = 300,
  String rating = 'calm',
  DateTime? time,
  List<double> holds = const [],
}) {
  return SessionRecord(
    practiceName: name,
    level: level,
    durationSeconds: duration,
    timestamp: time ?? DateTime.now(),
    checkinRating: rating,
    holdDurations: holds,
  );
}
