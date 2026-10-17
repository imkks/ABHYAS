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
  });
}
