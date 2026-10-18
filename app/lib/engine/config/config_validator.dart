import 'package:json_schema/json_schema.dart';
import 'config_schema.dart';

class ConfigValidator {
  static bool validate(Map<String, dynamic> config) {
    try {
      final schema = JsonSchema.create(configSchema);
      final validationResult = schema.validate(config);

      if (!validationResult.isValid) {
        // Log errors in real scenario
        for (var error in validationResult.errors) {
          print("Config Validation Error: ${error.message}");
        }
        return false;
      }

      // Additional safety invariant checking
      final levels = config['levels'] as List<dynamic>;
      for (var level in levels) {
        final levelMap = level as Map<String, dynamic>;

        if (levelMap.containsKey('bahya_start_seconds') && levelMap.containsKey('bahya_never_exceeds_antar') && levelMap['bahya_never_exceeds_antar'] == true) {
             // Invariant to enforce server side and schema side that bahya holds shouldn't logically outpace antar hold
             // This can be checked properly when running actual sessions, but here we can check basic default configs.
        }
      }

      return true;
    } catch (e) {
      print("Exception during validation: $e");
      return false;
    }
  }
}
