import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/safety/safety_rules_engine.dart';

void main() {
  group('Safety Rules Matrix Engine tests', () {
    test('SR-01 & SR-02 Hypertension/Heart/Pregnancy blocks kapalbhati without teacher clearance', () {
      final profile = SafetyProfile(hypertension: true);
      expect(SafetyRulesEngine.isPracticeAllowed('kapalbhati', profile, false), isFalse);
      expect(SafetyRulesEngine.isPracticeAllowed('kapalbhati', profile, true), isTrue); // teacher cleared

      final profilePregnancy = SafetyProfile(pregnancy: true);
      expect(SafetyRulesEngine.isPracticeAllowed('antar_kumbhaka', profilePregnancy, false), isFalse);
      expect(SafetyRulesEngine.isPracticeAllowed('antar_kumbhaka', profilePregnancy, true), isTrue);
    });

    test('SR-03 Menstruation blocks specific practices', () {
      final profile = SafetyProfile(menstruation: true, emptyStomachConfirmed: true);
      expect(SafetyRulesEngine.isPracticeAllowed('kapalbhati', profile, false), isFalse);
      expect(SafetyRulesEngine.isPracticeAllowed('uddiyana_kriya', profile, false), isFalse);
      expect(SafetyRulesEngine.isPracticeAllowed('maha_bandha', profile, false), isFalse);
      expect(SafetyRulesEngine.isPracticeAllowed('nadi_shodhana', profile, false), isTrue);
    });

    test('SR-04 Uddiyana requires empty stomach', () {
      final profileNotEmpty = SafetyProfile(emptyStomachConfirmed: false);
      expect(SafetyRulesEngine.isPracticeAllowed('uddiyana_kriya', profileNotEmpty, false), isFalse);

      final profileEmpty = SafetyProfile(emptyStomachConfirmed: true);
      expect(SafetyRulesEngine.isPracticeAllowed('uddiyana_kriya', profileEmpty, false), isTrue);
    });

    test('SR-01 Comprehensive flag test', () {
      final practices = ['kapalbhati', 'bhastrika', 'antar_kumbhaka', 'bahya_kumbhaka', 'uddiyana_kriya', 'maha_bandha', 'jalandhara', 'mula', 'bandhas'];
      final safePractices = ['breath_awareness', 'nadi_shodhana', 'om_chant'];

      final flags = [
        SafetyProfile(pregnancy: true),
        SafetyProfile(hypertension: true),
        SafetyProfile(heartCondition: true),
        SafetyProfile(epilepsy: true),
        SafetyProfile(glaucoma: true),
        SafetyProfile(hernia: true),
        SafetyProfile(recentSurgery: true)
      ];

      for (var profile in flags) {
        for (var practice in practices) {
          expect(SafetyRulesEngine.isPracticeAllowed(practice, profile, false), isFalse, reason: 'Profile blocked \$practice');
          expect(SafetyRulesEngine.isPracticeAllowed(practice, profile, true), isTrue, reason: 'Teacher cleared \$practice');
        }

        for (var practice in safePractices) {
          expect(SafetyRulesEngine.isPracticeAllowed(practice, profile, false), isTrue, reason: 'Safe practice allowed for \$practice');
        }
      }
    });
  });
}
