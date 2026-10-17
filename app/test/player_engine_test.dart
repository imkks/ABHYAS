import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/player/player_engine.dart';

void main() {
  group('Player Engine Tests', () {
    test('AC-2: Engine caps hold time properly', () {
      // userCht = 20s, fraction = 0.6 => userCap = 12s
      // levelCap = 30s
      final engine = PlayerEngine(
        holdCapFractionOfCht: 0.6,
        levelCapSeconds: 30,
        userChtSeconds: 20,
      );

      // Should be min(30, 12) = 12
      expect(engine.calculateMaxHoldSeconds(), equals(12));

      // Attempting to schedule 16s hold should be capped to 12s
      expect(engine.scheduleHold(16), equals(12));
    });

    test('Engine schedules full ratio if below cap', () {
      final engine = PlayerEngine(
        holdCapFractionOfCht: 0.6,
        levelCapSeconds: 30,
        userChtSeconds: 20,
      );

      // Attempting to schedule 8s hold, which is < 12s cap, should allow 8
      expect(engine.scheduleHold(8), equals(8));
    });

    test('AC-9: Returns to natural breath', () {
      final engine = PlayerEngine(
        holdCapFractionOfCht: 0.6,
        levelCapSeconds: 30,
        userChtSeconds: 20,
      );

      expect(engine.returnToNaturalBreath(), equals(PracticePhase.naturalBreath));
    });

    test('State machine cycles correctly', () {
      final engine = PlayerEngine(
        holdCapFractionOfCht: 0.6,
        levelCapSeconds: 30,
        userChtSeconds: 20,
      );

      PracticePhase phase = PracticePhase.puraka;
      phase = engine.getNextPhase(phase);
      expect(phase, equals(PracticePhase.antarKumbhaka));
      phase = engine.getNextPhase(phase);
      expect(phase, equals(PracticePhase.rechaka));
      phase = engine.getNextPhase(phase);
      expect(phase, equals(PracticePhase.bahyaKumbhaka));
      phase = engine.getNextPhase(phase);
      expect(phase, equals(PracticePhase.puraka));
    });
  });
}
