import 'package:json_schema/json_schema.dart';
import 'config_schema.dart';

class ConfigValidator {
  static bool validate(Map<String, dynamic> config) {
    try {
      final schema = JsonSchema.create(configSchema);
      final validationResult = schema.validate(config);

      if (!validationResult.isValid) {
        for (var error in validationResult.errors) {
          print("Config Validation Error: ${error.message}");
        }
        return false;
      }

      // Additional safety invariant checking
      final levels = config['levels'] as List<dynamic>;
      for (var level in levels) {
        final levelMap = level as Map<String, dynamic>;

        // Invariant: bahya_never_exceeds_antar
        if (levelMap['bahya_never_exceeds_antar'] == true) {
          if (levelMap.containsKey('ratio_ladder')) {
            final ladder = levelMap['ratio_ladder'] as List<dynamic>;
            for (var r in ladder) {
              final ratio = (r as List<dynamic>).map((e) => (e as num).toInt()).toList();
              if (ratio.length >= 4) {
                final antar = ratio[1];
                final bahya = ratio[3];
                if (bahya > antar) {
                  print("Safety Invariant Violation: Bahya hold ($bahya) exceeds Antar hold ($antar) in level ${levelMap['id']}");
                  return false;
                }
              }
            }
          }
        }
      }

      return true;
    } catch (e) {
      print("Exception during validation: $e");
      return false;
    }
  }
}
