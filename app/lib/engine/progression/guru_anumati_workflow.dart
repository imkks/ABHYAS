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
}

class GuruAnumatiWorkflow {
  final List<UnlockRequest> _requests = [];

  List<UnlockRequest> get requests => _requests;

  void requestUnlock(String studentId, int level) {
    _requests.add(UnlockRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: studentId,
      requestedLevel: level,
      requestedAt: DateTime.now(),
    ));
  }

  void processRequest(String requestId, UnlockStatus newStatus, {String? note}) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = newStatus;
      _requests[index].teacherNote = note;
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
