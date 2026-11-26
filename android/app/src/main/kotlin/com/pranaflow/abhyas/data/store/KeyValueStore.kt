package com.pranaflow.abhyas.data.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

private val Context.abhyasDataStore: DataStore<Preferences> by preferencesDataStore(name = "abhyas_offline_store")

/**
 * Abstract offline-first key-value store enabling Jetpack DataStore in production
 * and fast deterministic [InMemoryKeyValueStore] in JVM unit tests.
 */
interface KeyValueStore {
    suspend fun getString(key: String): String?
    suspend fun putString(key: String, value: String)
    suspend fun getBoolean(key: String, defaultValue: Boolean = false): Boolean
    suspend fun putBoolean(key: String, value: Boolean)
    suspend fun getInt(key: String, defaultValue: Int = 0): Int
    suspend fun putInt(key: String, value: Int)
    suspend fun getDouble(key: String, defaultValue: Double = 0.0): Double
    suspend fun putDouble(key: String, value: Double)
    suspend fun getStringList(key: String): List<String>
    suspend fun putStringList(key: String, value: List<String>)
    suspend fun remove(key: String)
    suspend fun clearAll()
}

class DataStoreKeyValueStore(
    private val dataStore: DataStore<Preferences>,
) : KeyValueStore {

    constructor(context: Context) : this(context.applicationContext.abhyasDataStore)

    private val json = Json

    override suspend fun getString(key: String): String? =
        dataStore.data.first()[stringPreferencesKey(key)]

    override suspend fun putString(key: String, value: String) {
        dataStore.edit { it[stringPreferencesKey(key)] = value }
    }

    override suspend fun getBoolean(key: String, defaultValue: Boolean): Boolean =
        dataStore.data.first()[booleanPreferencesKey(key)] ?: defaultValue

    override suspend fun putBoolean(key: String, value: Boolean) {
        dataStore.edit { it[booleanPreferencesKey(key)] = value }
    }

    override suspend fun getInt(key: String, defaultValue: Int): Int =
        dataStore.data.first()[intPreferencesKey(key)] ?: defaultValue

    override suspend fun putInt(key: String, value: Int) {
        dataStore.edit { it[intPreferencesKey(key)] = value }
    }

    override suspend fun getDouble(key: String, defaultValue: Double): Double =
        dataStore.data.first()[doublePreferencesKey(key)] ?: defaultValue

    override suspend fun putDouble(key: String, value: Double) {
        dataStore.edit { it[doublePreferencesKey(key)] = value }
    }

    override suspend fun getStringList(key: String): List<String> {
        val raw = dataStore.data.first()[stringPreferencesKey("${key}_json")]
        if (raw != null) {
            return runCatching { json.decodeFromString<List<String>>(raw) }.getOrDefault(emptyList())
        }
        return dataStore.data.first()[stringSetPreferencesKey(key)]?.toList() ?: emptyList()
    }

    override suspend fun putStringList(key: String, value: List<String>) {
        // Store as ordered JSON list to preserve insertion order and duplicates
        dataStore.edit { it[stringPreferencesKey("${key}_json")] = json.encodeToString(value) }
    }

    override suspend fun remove(key: String) {
        dataStore.edit {
            it.remove(stringPreferencesKey(key))
            it.remove(stringPreferencesKey("${key}_json"))
            it.remove(booleanPreferencesKey(key))
            it.remove(intPreferencesKey(key))
            it.remove(doublePreferencesKey(key))
            it.remove(stringSetPreferencesKey(key))
        }
    }

    override suspend fun clearAll() {
        dataStore.edit { it.clear() }
    }
}

class InMemoryKeyValueStore : KeyValueStore {
    private val mutex = Mutex()
    private val data = mutableMapOf<String, Any>()

    override suspend fun getString(key: String): String? = mutex.withLock { data[key] as? String }

    override suspend fun putString(key: String, value: String) {
        mutex.withLock { data[key] = value }
    }

    override suspend fun getBoolean(key: String, defaultValue: Boolean): Boolean =
        mutex.withLock { data[key] as? Boolean ?: defaultValue }

    override suspend fun putBoolean(key: String, value: Boolean) {
        mutex.withLock { data[key] = value }
    }

    override suspend fun getInt(key: String, defaultValue: Int): Int =
        mutex.withLock { data[key] as? Int ?: defaultValue }

    override suspend fun putInt(key: String, value: Int) {
        mutex.withLock { data[key] = value }
    }

    override suspend fun getDouble(key: String, defaultValue: Double): Double =
        mutex.withLock { data[key] as? Double ?: defaultValue }

    override suspend fun putDouble(key: String, value: Double) {
        mutex.withLock { data[key] = value }
    }

    @Suppress("UNCHECKED_CAST")
    override suspend fun getStringList(key: String): List<String> =
        mutex.withLock { (data[key] as? List<String>)?.toList() ?: emptyList() }

    override suspend fun putStringList(key: String, value: List<String>) {
        mutex.withLock { data[key] = value.toList() }
    }

    override suspend fun remove(key: String) {
        mutex.withLock { data.remove(key) }
    }

    override suspend fun clearAll() {
        mutex.withLock { data.clear() }
    }
}
