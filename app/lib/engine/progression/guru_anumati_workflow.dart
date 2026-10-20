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
  String? studentNote;

  UnlockRequest({
    required this.id,
    required this.studentId,
    required this.requestedLevel,
    required this.requestedAt,
    this.status = UnlockStatus.pending,
    this.teacherNote,
    this.studentNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'requestedLevel': requestedLevel,
    'requestedAt': requestedAt.toIso8601String(),
    'status': status.name,
    'teacherNote': teacherNote,
    'studentNote': studentNote,
  };

  factory UnlockRequest.fromJson(Map<String, dynamic> json) => UnlockRequest(
    id: json['id'],
    studentId: json['studentId'],
    requestedLevel: json['requestedLevel'],
    requestedAt: DateTime.parse(json['requestedAt']),
    status: UnlockStatus.values.firstWhere((e) => e.name == json['status']),
    teacherNote: json['teacherNote'],
    studentNote: json['studentNote'],
  );
}

class GuruAnumatiWorkflow {
  static const String _requestsKey = 'unlock_requests';

  Future<List<UnlockRequest>> getRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> requestsStr = prefs.getStringList(_requestsKey) ?? [];
    return requestsStr.map((str) => UnlockRequest.fromJson(json.decode(str))).toList();
  }

  Future<void> _saveRequests(List<UnlockRequest> requests) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> requestsStr = requests.map((req) => json.encode(req.toJson())).toList();
    await prefs.setStringList(_requestsKey, requestsStr);
  }

  Future<void> requestUnlock(String studentId, int level, {String? note}) async {
    final requests = await getRequests();

    // Don't request if already pending or approved
    if (requests.any((r) => r.requestedLevel == level && (r.status == UnlockStatus.pending || r.status == UnlockStatus.approved))) {
      return;
    }

    requests.add(UnlockRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      requestedLevel: level,
      requestedAt: DateTime.now(),
      studentNote: note,
    ));
    await _saveRequests(requests);
  }

  Future<void> processRequest(String requestId, UnlockStatus newStatus, {String? note}) async {
    final requests = await getRequests();
    final index = requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      requests[index].status = newStatus;
      requests[index].teacherNote = note;
      await _saveRequests(requests);
    }
  }

  Future<void> simulateTeacherApproval(int level, bool approve, String note) async {
    final requests = await getRequests();
    bool changed = false;
    for (var i = 0; i < requests.length; i++) {
      if (requests[i].requestedLevel == level && requests[i].status == UnlockStatus.pending) {
        requests[i].status = approve ? UnlockStatus.approved : UnlockStatus.denied;
        requests[i].teacherNote = note;
        changed = true;
      }
    }
    if (changed) {
      await _saveRequests(requests);
    }
  }

  Future<bool> isLevelApproved(int level) async {
    final requests = await getRequests();
    return requests.any((r) => r.requestedLevel == level && r.status == UnlockStatus.approved);
  }
}
