package com.pranaflow.abhyas.engine.progression

import kotlinx.serialization.Serializable

@Serializable
enum class UnlockStatus {
    PENDING,
    APPROVED,
    DENIED,
    CONDITIONS_ADDED,
}

@Serializable
data class UnlockRequest(
    val id: String,
    val studentId: String,
    val requestedLevel: Int,
    val requestedAtEpochMs: Long,
    val status: UnlockStatus = UnlockStatus.PENDING,
    val studentNote: String? = null,
    val teacherNote: String? = null,
    val consentSharedWithTeacher: Boolean = true,
)

@Serializable
data class AuditLogEntry(
    val id: String,
    val actorId: String,
    val action: String,
    val targetId: String,
    val reason: String,
    val timestampEpochMs: Long,
)

/**
 * Pure Kotlin Guru Anumati unlock workflow & audit log manager (FR-GM-07).
 * Defaults to open self-guided mode ([teacherGatingEnabled] = false) so all Sopana levels are open.
 */
class GuruAnumatiWorkflow(
    initialRequests: List<UnlockRequest> = emptyList(),
    initialClearedPractices: Set<String> = emptySet(),
    initialAuditLog: List<AuditLogEntry> = emptyList(),
    var teacherGatingEnabled: Boolean = false,
) {
    private val _requests = initialRequests.toMutableList()
    private val _clearedPractices = initialClearedPractices.toMutableSet()
    private val _auditLog = initialAuditLog.toMutableList()

    val requests: List<UnlockRequest> get() = _requests.toList()
    val clearedPractices: Set<String> get() = _clearedPractices.toSet()
    val auditLog: List<AuditLogEntry> get() = _auditLog.toList()

    fun requestUnlock(
        studentId: String,
        level: Int,
        timestampEpochMs: Long,
        studentNote: String? = null,
        consentSharedWithTeacher: Boolean = true,
    ): UnlockRequest {
        val req = UnlockRequest(
            id = "${studentId}_lvl${level}_$timestampEpochMs",
            studentId = studentId,
            requestedLevel = level,
            requestedAtEpochMs = timestampEpochMs,
            status = UnlockStatus.PENDING,
            studentNote = studentNote,
            consentSharedWithTeacher = consentSharedWithTeacher,
        )
        _requests.add(req)
        _auditLog.add(
            AuditLogEntry(
                id = "audit_$timestampEpochMs",
                actorId = studentId,
                action = "UNLOCK_REQUESTED_LEVEL_$level",
                targetId = req.id,
                reason = studentNote ?: "Student requested Sopana $level progression",
                timestampEpochMs = timestampEpochMs,
            ),
        )
        return req
    }

    fun processRequest(
        requestId: String,
        newStatus: UnlockStatus,
        teacherId: String,
        note: String,
        timestampEpochMs: Long,
    ): Boolean {
        val index = _requests.indexOfFirst { it.id == requestId }
        if (index == -1) return false

        val existing = _requests[index]
        _requests[index] = existing.copy(
            status = newStatus,
            teacherNote = note,
        )
        _auditLog.add(
            AuditLogEntry(
                id = "audit_${timestampEpochMs}_${requestId}",
                actorId = teacherId,
                action = "UNLOCK_${newStatus.name}_LEVEL_${existing.requestedLevel}",
                targetId = existing.studentId,
                reason = note,
                timestampEpochMs = timestampEpochMs,
            ),
        )
        return true
    }

    fun clearPracticeForStudent(
        practiceId: String,
        teacherId: String,
        studentId: String,
        reason: String,
        timestampEpochMs: Long,
    ) {
        val normalized = practiceId.trim().lowercase()
        _clearedPractices.add(normalized)
        _auditLog.add(
            AuditLogEntry(
                id = "audit_clear_${timestampEpochMs}_$normalized",
                actorId = teacherId,
                action = "SAFETY_CLEARANCE_$normalized",
                targetId = studentId,
                reason = reason,
                timestampEpochMs = timestampEpochMs,
            ),
        )
    }

    fun isLevelApproved(level: Int): Boolean {
        if (level <= 2) return true
        if (!teacherGatingEnabled) return true
        return _requests.any {
            it.requestedLevel == level &&
                (it.status == UnlockStatus.APPROVED || it.status == UnlockStatus.CONDITIONS_ADDED)
        }
    }

    fun approvedLevelSet(): Set<Int> =
        (1..7).filter { isLevelApproved(it) }.toSet()
}
