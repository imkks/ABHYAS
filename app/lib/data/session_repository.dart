import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class representing a completed practice session.
class SessionRecord {
  final String practiceName;
  final int level;
  final int durationSeconds;
  final DateTime timestamp;
  final String checkinRating; // calm, neutral, agitated, strained
  final List<double> holdDurations;
  final int? calmnessScore; // 1 to 10
  final int? preCalmnessScore; // 1 to 10
  final List<String> sensations;

  SessionRecord({
    required this.practiceName,
    required this.level,
    required this.durationSeconds,
    required this.timestamp,
    required this.checkinRating,
    this.holdDurations = const [],
    this.calmnessScore,
    this.preCalmnessScore,
    this.sensations = const [],
  });

  int get calmnessDelta {
    if (calmnessScore == null || preCalmnessScore == null) return 0;
    return (calmnessScore! - preCalmnessScore!);
  }

  Map<String, dynamic> toJson() => {
    'practiceName': practiceName,
    'level': level,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
    'checkinRating': checkinRating,
    'holdDurations': holdDurations,
    'calmnessScore': calmnessScore,
    'preCalmnessScore': preCalmnessScore,
    'sensations': sensations,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      practiceName: json['practiceName'] as String,
      level: json['level'] as int,
      durationSeconds: json['durationSeconds'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      checkinRating: json['checkinRating'] as String,
      holdDurations: (json['holdDurations'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? const [],
      calmnessScore: json['calmnessScore'] as int?,
      preCalmnessScore: json['preCalmnessScore'] as int?,
      sensations: (json['sensations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
    );
  }
}

/// Persists completed practice sessions and computes aggregate metrics.
class SessionRepository {
  static const String _sessionsKey = 'session_records';

  Future<void> logSession(SessionRecord session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_sessionsKey) ?? [];
    existing.add(json.encode(session.toJson()));
    await prefs.setStringList(_sessionsKey, existing);
  }

  Future<List<SessionRecord>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_sessionsKey) ?? [];
    return raw
        .map((str) => SessionRecord.fromJson(
            json.decode(str) as Map<String, dynamic>))
        .toList();
  }

  /// Total number of completed sessions (Tapas count).
  Future<int> getTapasCount() async {
    final sessions = await getSessions();
    return sessions.length;
  }

  /// Total minutes practiced across all sessions.
  Future<int> getTotalPracticeMinutes() async {
    final sessions = await getSessions();
    final totalSecs = sessions.fold(0, (sum, s) => sum + s.durationSeconds);
    return totalSecs ~/ 60;
  }

  /// Average calmness delta (post - pre) across all recorded sessions.
  Future<double> getAverageCalmnessDelta() async {
    final sessions = await getSessions();
    final valid = sessions.where((s) => s.calmnessScore != null && s.preCalmnessScore != null).toList();
    if (valid.isEmpty) return 0.0;
    final totalDelta = valid.fold(0, (sum, s) => sum + s.calmnessDelta);
    return totalDelta / valid.length;
  }

  /// Consecutive 'calm' checkin ratings counting backwards from the most recent session.
  Future<int> getComfortStreak() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return 0;

    // Sort by timestamp descending (most recent first)
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    for (final session in sessions) {
      if (session.checkinRating == 'calm') {
        streak++;
      } else {
        break; // Streak is interrupted by any non-calm rating
      }
    }
    return streak;
  }

  /// Average hold duration across all sessions that have hold data.
  Future<double> getAverageHold() async {
    final sessions = await getSessions();
    final allHolds = sessions
        .expand((s) => s.holdDurations)
        .toList();
    if (allHolds.isEmpty) return 0.0;
    return allHolds.reduce((a, b) => a + b) / allHolds.length;
  }

  /// Calculates the day-streak (consecutive unique days of practice).
  Future<int> getDailyPracticeStreak() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return 0;

    // Extract unique dates sorted descending
    final dates = sessions
        .map((s) => DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates.isEmpty || (dates.first != today && dates.first != yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
