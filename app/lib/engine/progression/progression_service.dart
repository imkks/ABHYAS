import 'package:shared_preferences/shared_preferences.dart';
import '../../data/session_repository.dart';

class LevelInfo {
  final int level;
  final String title;
  final String subtitle;
  final int minTapas;
  final int nextLevelTapas;
  final String ratioDescription;
  final List<int> ratio; // [puraka, antar, rechaka, bahya] in seconds
  final int kapalbhatiStrokes;
  final List<String> unlockedSeals;
  final String featureHighlight;

  LevelInfo({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.minTapas,
    required this.nextLevelTapas,
    required this.ratioDescription,
    required this.ratio,
    required this.kapalbhatiStrokes,
    required this.unlockedSeals,
    required this.featureHighlight,
  });
}

class UserProgression {
  final int level;
  final String title;
  final int totalTapas;
  final int currentLevelTapas;
  final int tapasNeededForNextLevel;
  final double progressPercent;
  final int dailyStreak;
  final List<String> earnedSeals;
  final String ratioDescription;
  final List<int> ratio;
  final int kapalbhatiStrokes;
  final String featureHighlight;

  UserProgression({
    required this.level,
    required this.title,
    required this.totalTapas,
    required this.currentLevelTapas,
    required this.tapasNeededForNextLevel,
    required this.progressPercent,
    required this.dailyStreak,
    required this.earnedSeals,
    required this.ratioDescription,
    required this.ratio,
    required this.kapalbhatiStrokes,
    required this.featureHighlight,
  });
}

class ProgressionService {
  static const String _bonusTapasKey = 'user_bonus_tapas_points';
  static const String _calibratedLevelKey = 'user_calibrated_sopana_level';
  static final ProgressionService _instance = ProgressionService._internal();
  factory ProgressionService() => _instance;
  ProgressionService._internal();

  final List<LevelInfo> _levels = [
    LevelInfo(
      level: 1,
      title: 'Prarambha (Seeker)',
      subtitle: 'Foundational Breath & Centering',
      minTapas: 0,
      nextLevelTapas: 300,
      ratioDescription: '1:0:1:0 (Natural Rhythm)',
      ratio: [4, 0, 4, 0],
      kapalbhatiStrokes: 30,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra'],
      featureHighlight: 'Gentle 4s In : 4s Out breath pacer',
    ),
    LevelInfo(
      level: 2,
      title: 'Abhyasi (Dedicated)',
      subtitle: 'Extended Exhalation & Calming',
      minTapas: 300,
      nextLevelTapas: 750,
      ratioDescription: '1:0:2:0 (Extended Exhale)',
      ratio: [4, 0, 8, 0],
      kapalbhatiStrokes: 45,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra'],
      featureHighlight: '1:0:2:0 Parasympathetic deep relaxation',
    ),
    LevelInfo(
      level: 3,
      title: 'Antaranga (Inward Journeyer)',
      subtitle: 'Internal Retention & Throat Lock',
      minTapas: 750,
      nextLevelTapas: 1500,
      ratioDescription: '1:1:2:0 (Antar Kumbhaka)',
      ratio: [4, 4, 8, 0],
      kapalbhatiStrokes: 60,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra', 'Nasika Mudra', 'Jalandhara Bandha'],
      featureHighlight: 'Internal breath hold + Jalandhara Bandha cue',
    ),
    LevelInfo(
      level: 4,
      title: 'Shaktiman (Vital Force)',
      subtitle: 'Bellows Breath & Root Energy',
      minTapas: 1500,
      nextLevelTapas: 2500,
      ratioDescription: '1:2:2:0 (Vital Energy)',
      ratio: [4, 8, 8, 0],
      kapalbhatiStrokes: 80,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra', 'Nasika Mudra', 'Jalandhara Bandha', 'Shanmukhi Mudra', 'Mula Bandha'],
      featureHighlight: 'Bhastrika (Bellows breath) & Mula Bandha',
    ),
    LevelInfo(
      level: 5,
      title: 'Kumbhaka Siddha (Breath Master)',
      subtitle: 'Classical 1:4:2:0 Ratio Mastery',
      minTapas: 2500,
      nextLevelTapas: 4000,
      ratioDescription: '1:4:2:0 (Classical Kumbhaka)',
      ratio: [4, 16, 8, 0],
      kapalbhatiStrokes: 100,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra', 'Nasika Mudra', 'Jalandhara Bandha', 'Shanmukhi Mudra', 'Mula Bandha', 'Prana Mudra'],
      featureHighlight: 'Deep classical 1:4:2:0 retention ladder',
    ),
    LevelInfo(
      level: 6,
      title: 'Bandha Yogi (Energy Master)',
      subtitle: 'External Retention & The Great Lock',
      minTapas: 4000,
      nextLevelTapas: 6000,
      ratioDescription: '1:4:2:2 (Bahya Retention)',
      ratio: [4, 16, 8, 8],
      kapalbhatiStrokes: 120,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra', 'Nasika Mudra', 'Jalandhara Bandha', 'Shanmukhi Mudra', 'Mula Bandha', 'Uddiyana Bandha', 'Maha Bandha'],
      featureHighlight: 'Bahya Kumbhaka + Maha Bandha (Tri-lock)',
    ),
    LevelInfo(
      level: 7,
      title: 'Dhyani (Absorbed Master)',
      subtitle: 'Transcendent Stillness & Ajapa Japa',
      minTapas: 6000,
      nextLevelTapas: 10000,
      ratioDescription: 'Samadhi Dhyana Pacing',
      ratio: [6, 24, 12, 0],
      kapalbhatiStrokes: 120,
      unlockedSeals: ['Gyan Mudra', 'Chin Mudra', 'Dhyana Mudra', 'Nasika Mudra', 'Jalandhara Bandha', 'Shanmukhi Mudra', 'Mula Bandha', 'Uddiyana Bandha', 'Maha Bandha', 'Shambhavi Mudra'],
      featureHighlight: 'Shambhavi Mudra & Silent Ajapa Japa',
    ),
  ];

  Future<UserProgression> getProgression() async {
    final sessionRepo = SessionRepository();
    final prefs = await SharedPreferences.getInstance();

    final sessions = await sessionRepo.getSessions();
    final streak = await sessionRepo.getDailyPracticeStreak();
    final bonusTapas = prefs.getInt(_bonusTapasKey) ?? 0;

    // Calculate total Tapas XP:
    // 10 Tapas per practice minute + streak bonuses
    int sessionTapas = 0;
    for (final s in sessions) {
      final mins = (s.durationSeconds / 60).round();
      sessionTapas += (mins * 10).clamp(10, 600);
      if (s.checkinRating == 'calm') {
        sessionTapas += 15; // Bonus for calm completion
      }
    }

    final totalTapas = sessionTapas + (streak * 50) + bonusTapas;

    // Determine level from Tapas
    LevelInfo currentLevelInfo = _levels.first;
    for (int i = _levels.length - 1; i >= 0; i--) {
      if (totalTapas >= _levels[i].minTapas) {
        currentLevelInfo = _levels[i];
        break;
      }
    }

    // If user has calibrated their apt level via breath test, honor it
    final calibratedLevel = prefs.getInt(_calibratedLevelKey);
    if (calibratedLevel != null && calibratedLevel > currentLevelInfo.level) {
      currentLevelInfo = getLevelInfo(calibratedLevel);
    }

    final int rangeStart = currentLevelInfo.minTapas;
    final int rangeEnd = currentLevelInfo.nextLevelTapas;
    final int inLevelXP = totalTapas - rangeStart;
    final int neededForNext = rangeEnd - rangeStart;
    final double percent = (inLevelXP / neededForNext).clamp(0.0, 1.0);

    return UserProgression(
      level: currentLevelInfo.level,
      title: currentLevelInfo.title,
      totalTapas: totalTapas,
      currentLevelTapas: inLevelXP,
      tapasNeededForNextLevel: neededForNext,
      progressPercent: percent,
      dailyStreak: streak,
      earnedSeals: currentLevelInfo.unlockedSeals,
      ratioDescription: currentLevelInfo.ratioDescription,
      ratio: currentLevelInfo.ratio,
      kapalbhatiStrokes: currentLevelInfo.kapalbhatiStrokes,
      featureHighlight: currentLevelInfo.featureHighlight,
    );
  }

  LevelInfo getLevelInfo(int level) {
    return _levels.firstWhere((l) => l.level == level, orElse: () => _levels.first);
  }

  Future<void> saveCalibratedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calibratedLevelKey, level);
    final target = getLevelInfo(level);
    final currentBonus = prefs.getInt(_bonusTapasKey) ?? 0;
    if (currentBonus < target.minTapas) {
      await prefs.setInt(_bonusTapasKey, target.minTapas);
    }
  }

  int calculateLevelFromCht(double chtSeconds) {
    if (chtSeconds < 15.0) return 1;
    if (chtSeconds < 25.0) return 2;
    if (chtSeconds < 40.0) return 3;
    if (chtSeconds < 60.0) return 4;
    return 5;
  }
}
