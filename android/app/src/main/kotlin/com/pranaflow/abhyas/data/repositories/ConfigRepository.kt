package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.store.KeyValueStore
import com.pranaflow.abhyas.engine.config.ConfigValidationResult
import com.pranaflow.abhyas.engine.config.ConfigValidator
import com.pranaflow.abhyas.engine.config.PracticeConfig
import com.pranaflow.abhyas.engine.config.SeedConfig

/**
 * Manages versioned remote-editable [PracticeConfig] JSON with offline caching and strict
 * [ConfigValidator] enforcement before activation (SRS Section 8, NFR-01, FR-TC-06).
 */
class ConfigRepository(
    private val store: KeyValueStore,
) {
    suspend fun getActiveConfig(): PracticeConfig {
        val cachedJson = store.getString(KEY_ACTIVE_CONFIG_JSON)
        if (cachedJson != null) {
            val validation = ConfigValidator.validateJson(cachedJson)
            if (validation.isValid && validation.parsedConfig != null) {
                return validation.parsedConfig!!
            }
        }
        return SeedConfig.defaultConfig
    }

    /**
     * Validates and promotes a remote/teacher-published config JSON.
     * Rejects any config violating schema or safety invariants, preserving previous active config.
     */
    suspend fun tryApplyRemoteConfig(rawJson: String): ConfigValidationResult {
        val validation = ConfigValidator.validateJson(rawJson)
        if (validation.isValid && validation.parsedConfig != null) {
            val previous = store.getString(KEY_ACTIVE_CONFIG_JSON)
            if (previous != null) {
                store.putString(KEY_PREVIOUS_CONFIG_JSON, previous)
            }
            store.putString(KEY_ACTIVE_CONFIG_JSON, rawJson)
        }
        return validation
    }

    suspend fun rollbackToPreviousConfig(): Boolean {
        val previous = store.getString(KEY_PREVIOUS_CONFIG_JSON) ?: return false
        val validation = ConfigValidator.validateJson(previous)
        if (!validation.isValid) return false
        store.putString(KEY_ACTIVE_CONFIG_JSON, previous)
        return true
    }

    companion object {
        private const val KEY_ACTIVE_CONFIG_JSON = "active_practice_config_json"
        private const val KEY_PREVIOUS_CONFIG_JSON = "previous_practice_config_json"
    }
}
