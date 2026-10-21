import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/engine/config/config_models.dart';
import 'package:abhyas/engine/config/config_validator.dart';
import 'package:abhyas/engine/config/seed_config.dart';

void main() {
  group('PracticeConfig & seedConfig', () {
    test('seedConfig passes ConfigValidator schema and invariants', () {
      final isValid = ConfigValidator.validate(seedConfig);
      expect(isValid, true);
    });

    test('PracticeConfig.fromJson successfully parses seedConfig', () {
      final config = PracticeConfig.fromJson(seedConfig);
      expect(config.configVersion, '0.1.0');
      expect(config.levels.length, 7);
      expect(config.levels[0].name, 'Prarambha');
      expect(config.levels[0].gate, 'self');
      expect(config.levels[1].name, 'Abhyasa');
      expect(config.levels[2].name, 'Antar');
      expect(config.levels[2].requiresTeacherApproval, true);
      expect(config.levels[6].name, 'Dhyana');
      expect(config.levels[6].gate, 'guru_only');
    });

    test('getLevel retrieves correct level by ID', () {
      final config = PracticeConfig.fromJson(seedConfig);
      final level3 = config.getLevel(3);
      expect(level3, isNotNull);
      expect(level3!.name, 'Antar');
      expect(level3.bandhas, contains('jalandhara'));

      final invalid = config.getLevel(99);
      expect(invalid, isNull);
    });

    test('ConfigValidator rejects bahya hold exceeding antar hold', () {
      final invalidConfig = Map<String, dynamic>.from(seedConfig);
      invalidConfig['levels'] = [
        {
          "id": 6,
          "name": "Bahya",
          "gate": "teacher",
          "practices": ["bahya_kumbhaka"],
          "ratio_ladder": [
            [1, 2, 2, 4] // Bahya (4) exceeds Antar (2)
          ],
          "base_count": 4,
          "mudras": [],
          "bandhas": [],
          "bahya_never_exceeds_antar": true,
          "pariksha": {}
        }
      ];

      final isValid = ConfigValidator.validate(invalidConfig);
      expect(isValid, false);
    });
  });
}
