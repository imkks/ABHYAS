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

  SessionRecord({
    required this.practiceName,
    required this.level,
    required this.durationSeconds,
    required this.timestamp,
    required this.checkinRating,
    this.holdDurations = const [],
  });

  Map<String, dynamic> toJson() => {
    'practiceName': practiceName,
    'level': level,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp.toIso8601String(),
    'checkinRating': checkinRating,
    'holdDurations': holdDurations,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      practiceName: json['practiceName'] as String,
      level: json['level'] as int,
      durationSeconds: json['durationSeconds'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      checkinRating: json['checkinRating'] as String,
      holdDurations: (json['holdDurations'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
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
        break;
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
}
