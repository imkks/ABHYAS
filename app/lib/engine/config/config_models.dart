/// Strongly typed domain models deserializing configuration from seed_config or remote JSON.

class PracticeConfig {
  final String configVersion;
  final double matraDefaultSeconds;
  final double holdCapFractionOfCht;
  final int comfortStreakRequiredForStep;
  final int vishramaDaysPerWeek;
  final List<SopanaLevel> levels;
  final WeaningConfig? weaning;

  PracticeConfig({
    required this.configVersion,
    required this.matraDefaultSeconds,
    required this.holdCapFractionOfCht,
    required this.comfortStreakRequiredForStep,
    required this.vishramaDaysPerWeek,
    required this.levels,
    this.weaning,
  });

  factory PracticeConfig.fromJson(Map<String, dynamic> json) {
    return PracticeConfig(
      configVersion: json['config_version'] as String? ?? '0.1.0',
      matraDefaultSeconds: (json['matra_default_seconds'] as num?)?.toDouble() ?? 1.0,
      holdCapFractionOfCht: (json['hold_cap_fraction_of_cht'] as num?)?.toDouble() ?? 0.6,
      comfortStreakRequiredForStep: json['comfort_streak_required_for_step'] as int? ?? 5,
      vishramaDaysPerWeek: json['vishrama_days_per_week'] as int? ?? 1,
      levels: (json['levels'] as List<dynamic>? ?? [])
          .map((l) => SopanaLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
      weaning: json['weaning'] != null
          ? WeaningConfig.fromJson(json['weaning'] as Map<String, dynamic>)
          : null,
    );
  }

  SopanaLevel? getLevel(int levelId) {
    final matches = levels.where((l) => l.id == levelId);
    return matches.isNotEmpty ? matches.first : null;
  }
}

class SopanaLevel {
  final int id;
  final String name;
  final String gate; // 'self', 'streak', 'teacher', 'guru_only'
  final List<String> practices;
  final List<List<int>> ratioLadder;
  final int baseCount;
  final List<String> mudras;
  final List<String> bandhas;
  final ParikshaConfig pariksha;
  final Map<String, dynamic>? extraConfig;

  SopanaLevel({
    required this.id,
    required this.name,
    required this.gate,
    required this.practices,
    required this.ratioLadder,
    required this.baseCount,
    required this.mudras,
    required this.bandhas,
    required this.pariksha,
    this.extraConfig,
  });

  factory SopanaLevel.fromJson(Map<String, dynamic> json) {
    return SopanaLevel(
      id: json['id'] as int,
      name: json['name'] as String,
      gate: json['gate'] as String? ?? 'self',
      practices: (json['practices'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      ratioLadder: (json['ratio_ladder'] as List<dynamic>? ?? [])
          .map((r) => (r as List<dynamic>).map((e) => (e as num).toInt()).toList())
          .toList(),
      baseCount: json['base_count'] as int? ?? 4,
      mudras: (json['mudras'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      bandhas: (json['bandhas'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      pariksha: ParikshaConfig.fromJson(
        json['pariksha'] as Map<String, dynamic>? ?? {},
      ),
      extraConfig: json,
    );
  }

  bool get requiresTeacherApproval => gate == 'teacher' || gate == 'guru_only';
}

class ParikshaConfig {
  final int? minSessions;
  final int? consecutiveDaysWindow;
  final bool chtRequired;
  final bool teacherSignoff;
  final bool liveOrVideoReview;
  final bool guruOnly;

  ParikshaConfig({
    this.minSessions,
    this.consecutiveDaysWindow,
    this.chtRequired = false,
    this.teacherSignoff = false,
    this.liveOrVideoReview = false,
    this.guruOnly = false,
  });

  factory ParikshaConfig.fromJson(Map<String, dynamic> json) {
    return ParikshaConfig(
      minSessions: json['min_sessions'] as int?,
      consecutiveDaysWindow: json['consecutive_days_window'] as int?,
      chtRequired: json['cht_required'] as bool? ?? false,
      teacherSignoff: json['teacher_signoff'] as bool? ?? false,
      liveOrVideoReview: json['live_or_video_review'] as bool? ?? false,
      guruOnly: json['guru_only'] as bool? ?? false,
    );
  }

  String get summaryDescription {
    final List<String> requirements = [];
    if (minSessions != null) requirements.add('$minSessions completed sessions');
    if (consecutiveDaysWindow != null) requirements.add('within $consecutiveDaysWindow days streak');
    if (chtRequired) requirements.add('CHT benchmark assessment');
    if (teacherSignoff) requirements.add('Guru Anumati teacher sign-off');
    if (liveOrVideoReview) requirements.add('Live / video form review');
    if (guruOnly) requirements.add('Direct Guru transmission only');
    return requirements.isEmpty ? 'Self-evaluated readiness' : requirements.join(' · ');
  }
}

class WeaningConfig {
  final List<int> stageMinWeeks;
  final List<int> stageMinConsecutiveSessions;
  final int graduationConsecutiveSessions;

  WeaningConfig({
    required this.stageMinWeeks,
    required this.stageMinConsecutiveSessions,
    required this.graduationConsecutiveSessions,
  });

  factory WeaningConfig.fromJson(Map<String, dynamic> json) {
    return WeaningConfig(
      stageMinWeeks: (json['stage_min_weeks'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      stageMinConsecutiveSessions: (json['stage_min_consecutive_sessions'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      graduationConsecutiveSessions: json['graduation_consecutive_sessions'] as int? ?? 3,
    );
  }
}
