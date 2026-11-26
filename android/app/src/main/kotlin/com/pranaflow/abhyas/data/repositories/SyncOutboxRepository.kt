package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.SyncOutboxItem
import com.pranaflow.abhyas.data.store.KeyValueStore
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.concurrent.atomic.AtomicLong

/**
 * Optional local sync outbox (kept modular for unit tests; unused in local-only default container).
 */
class SyncOutboxRepository(
    private val store: KeyValueStore,
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun enqueue(
        entityType: String,
        payloadJson: String,
        createdAtEpochMs: Long = System.currentTimeMillis(),
    ): SyncOutboxItem {
        val item = SyncOutboxItem(
            id = "sync_${entityType}_${createdAtEpochMs}_${sequence.incrementAndGet()}",
            entityType = entityType,
            payloadJson = payloadJson,
            createdAtEpochMs = createdAtEpochMs,
            synced = false,
        )
        val list = getAll().toMutableList()
        list.add(item)
        store.putStringList(KEY_OUTBOX, list.map { json.encodeToString(it) })
        return item
    }

    suspend fun getAll(): List<SyncOutboxItem> =
        store.getStringList(KEY_OUTBOX).mapNotNull { raw ->
            runCatching { json.decodeFromString<SyncOutboxItem>(raw) }.getOrNull()
        }

    suspend fun getPending(): List<SyncOutboxItem> = getAll().filter { !it.synced }

    suspend fun markSynced(ids: Set<String>) {
        val updated = getAll().map { item ->
            if (item.id in ids) item.copy(synced = true) else item
        }
        store.putStringList(KEY_OUTBOX, updated.map { json.encodeToString(it) })
    }

    suspend fun flushWithTransport(
        transport: suspend (List<SyncOutboxItem>) -> Set<String>,
    ): Int {
        val pending = getPending()
        if (pending.isEmpty()) return 0
        val succeededIds = transport(pending)
        if (succeededIds.isNotEmpty()) {
            markSynced(succeededIds)
        }
        return succeededIds.size
    }

    companion object {
        private const val KEY_OUTBOX = "offline_sync_outbox"
        private val sequence = AtomicLong(0L)
    }
}
