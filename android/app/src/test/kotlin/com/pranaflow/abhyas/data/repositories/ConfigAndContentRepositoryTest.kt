package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.store.InMemoryKeyValueStore
import com.pranaflow.abhyas.engine.config.SeedConfig
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ConfigAndContentRepositoryTest {

    @Test
    fun `ConfigRepository rejects unsafe remote config and supports validated rollback`() = runTest {
        val repo = ConfigRepository(InMemoryKeyValueStore())
        assertEquals("0.1.0", repo.getActiveConfig().configVersion)

        val validUpdate = SeedConfig.SEED_JSON.replace(""""config_version": "0.1.0"""", """"config_version": "0.2.0"""")
        val applyOk = repo.tryApplyRemoteConfig(validUpdate)
        assertTrue(applyOk.isValid)
        assertEquals("0.2.0", repo.getActiveConfig().configVersion)

        // Unsafe config (bahya > antar) must be rejected and leave active config untouched
        val unsafeUpdate = validUpdate.replace("[1, 2, 2, 0], [1, 3, 2, 0], [1, 4, 2, 0]", "[1, 2, 2, 5]")
        val applyBad = repo.tryApplyRemoteConfig(unsafeUpdate)
        assertFalse(applyBad.isValid)
        assertEquals("0.2.0", repo.getActiveConfig().configVersion)

        // Valid update 0.3.0 then rollback to 0.2.0
        val v3 = validUpdate.replace(""""config_version": "0.2.0"""", """"config_version": "0.3.0"""")
        assertTrue(repo.tryApplyRemoteConfig(v3).isValid)
        assertEquals("0.3.0", repo.getActiveConfig().configVersion)
        assertTrue(repo.rollbackToPreviousConfig())
        assertEquals("0.2.0", repo.getActiveConfig().configVersion)
    }

    @Test
    fun `ContentRepository enforces FR-CM-02 teacher_approved filter in pilot builds`() {
        val manifestJson = """
        {
          "version": "0.1.0",
          "items": [
            {"id": "mantra_om", "type": "mantra", "language": "sa", "tradition_tags": ["all"], "status": "placeholder", "content_path": "content/mantras/om.json"},
            {"id": "mantra_approved", "type": "mantra", "language": "sa", "tradition_tags": ["Shaiva"], "status": "teacher_approved", "reviewer": "Acharya", "content_path": "content/mantras/approved.json"}
          ]
        }
        """
        val assets = mapOf(
            "content/manifest.json" to manifestJson,
            "content/mantras/om.json" to """{"text":"[CONTENT PENDING – TEACHER REVIEW]"}""",
            "content/mantras/approved.json" to """{"text":"Approved content"}""",
        )

        val devRepo = ContentRepository(assetReader = { assets[it] }, pilotMode = false)
        assertEquals(2, devRepo.getAvailableItems("Shaiva").size)

        val pilotRepo = ContentRepository(assetReader = { assets[it] }, pilotMode = true)
        val pilotItems = pilotRepo.getAvailableItems("Shaiva")
        assertEquals(1, pilotItems.size)
        assertEquals("mantra_approved", pilotItems.first().id)

        // Attempting to read placeholder item in pilot mode yields placeholder guard
        val unapprovedEntry = devRepo.loadManifest().items.first()
        assertEquals("[CONTENT PENDING – TEACHER REVIEW]", pilotRepo.loadItemRaw(unapprovedEntry))
    }
}
