const Map<String, dynamic> seedConfig = {
  "config_version": "0.1.0",
  "matra_default_seconds": 1.0,
  "hold_cap_fraction_of_cht": 0.6,
  "comfort_streak_required_for_step": 5,
  "vishrama_days_per_week": 1,
  "levels": [
    {
      "id": 1, "name": "Prarambha", "gate": "self",
      "practices": ["breath_awareness", "om_chant", "bhramari", "nadi_shodhana_basic"],
      "ratio_ladder": [[1,0,1,0]], "base_count": 4,
      "mudras": ["gyan", "chin", "dhyana"], "bandhas": [],
      "pariksha": { "min_sessions": 21 }
    },
    {
      "id": 2, "name": "Abhyasa", "gate": "streak",
      "practices": ["kapalbhati", "ujjayi", "nadi_shodhana_nasika"],
      "ratio_ladder": [[1,0,1,0],[1,0,2,0]], "base_count": 4,
      "kapalbhati": { "strokes_per_min": 60, "strokes_per_round_ladder": [30, 45, 60], "rounds": 3 },
      "mudras": ["nasika", "shanmukhi"], "bandhas": [],
      "pariksha": { "min_sessions": 42, "consecutive_days_window": 21 }
    },
    {
      "id": 3, "name": "Antar", "gate": "teacher",
      "practices": ["sheetali", "sheetkari", "antar_kumbhaka_short"],
      "ratio_ladder": [[1,1,2,0],[1,2,2,0]], "base_count": 4,
      "mudras": ["prana", "apana"], "bandhas": ["jalandhara"],
      "pariksha": { "cht_required": true, "teacher_signoff": true }
    },
    {
      "id": 4, "name": "Shakti", "gate": "teacher",
      "practices": ["bhastrika", "surya_bhedana", "kapalbhati_advanced"],
      "ratio_ladder": [[1,2,2,0],[1,3,2,0]], "base_count": 4,
      "bandhas": ["jalandhara", "mula"],
      "pariksha": { "teacher_signoff": true }
    },
    {
      "id": 5, "name": "Kumbhaka", "gate": "teacher",
      "practices": ["nadi_shodhana_full"],
      "ratio_ladder": [[1,2,2,0],[1,3,2,0],[1,4,2,0]], "base_count": 4,
      "bandhas": ["jalandhara", "mula"],
      "pariksha": { "teacher_signoff": true, "teacher_observes_early_sessions": true }
    },
    {
      "id": 6, "name": "Bahya", "gate": "teacher",
      "practices": ["bahya_kumbhaka", "uddiyana_kriya", "maha_bandha"],
      "bahya_start_seconds": 4, "bahya_never_exceeds_antar": true,
      "bandhas": ["uddiyana", "maha_bandha"],
      "pariksha": { "teacher_signoff": true, "live_or_video_review": true }
    },
    {
      "id": 7, "name": "Dhyana", "gate": "guru_only",
      "practices": ["trataka", "antar_mouna", "ajapa_japa", "yoga_nidra_advanced"],
      "mudras": ["maha_mudra", "maha_bheda", "viparita_karani", "shambhavi"],
      "ratio_cap_default": [6,24,12,0],
      "pariksha": { "guru_only": true }
    }
  ],
  "weaning": {
    "stage_min_weeks": [3, 3, 3, 3, 0],
    "stage_min_consecutive_sessions": [10, 10, 10, 10, 0],
    "graduation_consecutive_sessions": 3
  }
};
