// Config Schema Draft
const Map<String, dynamic> configSchema = {
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": [
    "config_version",
    "matra_default_seconds",
    "hold_cap_fraction_of_cht",
    "comfort_streak_required_for_step",
    "vishrama_days_per_week",
    "levels",
    "weaning"
  ],
  "properties": {
    "config_version": {"type": "string"},
    "matra_default_seconds": {"type": "number"},
    "hold_cap_fraction_of_cht": {"type": "number", "minimum": 0.0, "maximum": 1.0},
    "comfort_streak_required_for_step": {"type": "integer"},
    "vishrama_days_per_week": {"type": "integer"},
    "levels": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "name", "gate", "practices", "pariksha"],
        "properties": {
          "id": {"type": "integer"},
          "name": {"type": "string"},
          "gate": {"type": "string", "enum": ["self", "streak", "teacher", "guru_only"]},
          "practices": {
            "type": "array",
            "items": {"type": "string"}
          },
          "ratio_ladder": {
            "type": "array",
            "items": {
              "type": "array",
              "items": {"type": "number"},
              "minItems": 4,
              "maxItems": 4
            }
          },
          "base_count": {"type": "integer"},
          "bahya_start_seconds": {"type": "number"},
          "bahya_never_exceeds_antar": {"type": "boolean"},
          "ratio_cap_default": {
            "type": "array",
            "items": {"type": "number"},
            "minItems": 4,
            "maxItems": 4
          },
          "mudras": {
             "type": "array",
             "items": {"type": "string"}
          },
          "bandhas": {
             "type": "array",
             "items": {"type": "string"}
          },
          "pariksha": {"type": "object"}
        }
      }
    },
    "weaning": {
      "type": "object",
      "required": ["stage_min_weeks", "stage_min_consecutive_sessions", "graduation_consecutive_sessions"],
      "properties": {
        "stage_min_weeks": {
          "type": "array",
          "items": {"type": "integer"}
        },
        "stage_min_consecutive_sessions": {
          "type": "array",
          "items": {"type": "integer"}
        },
        "graduation_consecutive_sessions": {"type": "integer"}
      }
    }
  }
};
