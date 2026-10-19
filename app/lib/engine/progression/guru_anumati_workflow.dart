import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum UnlockStatus { pending, approved, denied, conditions_added }

class UnlockRequest {
  final String id;
  final String studentId;
  final int requestedLevel;
  final DateTime requestedAt;
  UnlockStatus status;
  String? teacherNote;

  UnlockRequest({
    required this.id,
    required this.studentId,
    required this.requestedLevel,
    required this.requestedAt,
    this.status = UnlockStatus.pending,
    this.teacherNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'requestedLevel': requestedLevel,
    'requestedAt': requestedAt.toIso8601String(),
    'status': status.name,
    'teacherNote': teacherNote,
  };

  factory UnlockRequest.fromJson(Map<String, dynamic> json) {
    return UnlockRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      requestedLevel: json['requestedLevel'] as int,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: UnlockStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UnlockStatus.pending,
      ),
      teacherNote: json['teacherNote'] as String?,
    );
  }
}

class GuruAnumatiWorkflow {
  static const String _storageKey = 'guru_anumati_requests';
  static final GuruAnumatiWorkflow _instance = GuruAnumatiWorkflow._internal();
  factory GuruAnumatiWorkflow() => _instance;

  GuruAnumatiWorkflow._internal() {
    _loadFromDisk();
  }

  final List<UnlockRequest> _requests = [];

  List<UnlockRequest> get requests => List.unmodifiable(_requests);

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null) {
        _requests.clear();
        for (final item in rawList) {
          _requests.add(UnlockRequest.fromJson(json.decode(item) as Map<String, dynamic>));
        }
      }
    } catch (_) {
      // Graceful fallback for tests or if uninitialized
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = _requests.map((r) => json.encode(r.toJson())).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }

  void requestUnlock(String studentId, int level) {
    _requests.add(UnlockRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      requestedLevel: level,
      requestedAt: DateTime.now(),
    ));
    _saveToDisk();
  }

  void processRequest(String requestId, UnlockStatus newStatus, {String? note}) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = newStatus;
      _requests[index].teacherNote = note;
      _saveToDisk();
    }
  }

  void simulateTeacherApproval(int level, bool approve, String note) {
    final reqs = _requests.where((r) => r.requestedLevel == level && r.status == UnlockStatus.pending).toList();
    for (var r in reqs) {
      processRequest(r.id, approve ? UnlockStatus.approved : UnlockStatus.denied, note: note);
    }
  }

  bool isLevelApproved(int level) {
    return _requests.any((r) => r.requestedLevel == level && r.status == UnlockStatus.approved);
  }
}
