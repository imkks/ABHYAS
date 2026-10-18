import 'package:flutter/foundation.dart';

enum UnlockStatus {
  pending,
  approved,
  denied
}

class UnlockRequest {
  final int requestedLevel;
  final DateTime requestDate;
  UnlockStatus status;
  String? teacherNote;

  UnlockRequest({
    required this.requestedLevel,
    required this.requestDate,
    this.status = UnlockStatus.pending,
    this.teacherNote,
  });
}

class GuruAnumatiWorkflow {
  final List<UnlockRequest> _requests = [];

  List<UnlockRequest> get requests => _requests;

  /// FR-GM-07: The student requests an unlock
  void requestUnlock(int level) {
    // Check if there's already a pending request for this level
    final existing = _requests.where((r) => r.requestedLevel == level && r.status == UnlockStatus.pending);
    if (existing.isNotEmpty) {
      return; // Already pending
    }

    _requests.add(UnlockRequest(
      requestedLevel: level,
      requestDate: DateTime.now(),
    ));
  }

  /// Mock function for Teacher Console approval (Phase 2 local test)
  void simulateTeacherApproval(int level, bool approved, String? note) {
    for (var request in _requests) {
      if (request.requestedLevel == level && request.status == UnlockStatus.pending) {
        request.status = approved ? UnlockStatus.approved : UnlockStatus.denied;
        request.teacherNote = note;
      }
    }
  }

  bool isLevelApproved(int level) {
    final existing = _requests.where((r) => r.requestedLevel == level && r.status == UnlockStatus.approved);
    return existing.isNotEmpty;
  }
}
