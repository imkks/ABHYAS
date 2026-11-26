package com.pranaflow.abhyas.data.repositories

import com.pranaflow.abhyas.data.models.CustomMantra
import com.pranaflow.abhyas.data.models.SavedCustomRoutine
import com.pranaflow.abhyas.data.store.KeyValueStore
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Persists classical and user-added mantras, active Digital Mala counts & rounds,
 * daily Sankalp intention, and saved Custom Sadhana routines.
 */
class MantraAndRoutineRepository(
    private val store: KeyValueStore,
) {
    private val json = Json { ignoreUnknownKeys = true }

    val defaultMantras: List<CustomMantra> = listOf(
        CustomMantra(
            id = "radha",
            name = "Radha Radha",
            text = "राधा राधा",
            transliteration = "Rādhā Rādhā",
            meaning = "The sweet, primordial vibration of pure devotion and inner stillness.",
        ),
        CustomMantra(
            id = "om",
            name = "Om (Pranava)",
            text = "ॐ",
            transliteration = "Oṁ",
            meaning = "The primordial sacred sound of creation.",
        ),
        CustomMantra(
            id = "om_namah_shivaya",
            name = "Om Namah Shivaya",
            text = "ॐ नमः शिवाय",
            transliteration = "Oṁ Namaḥ Śivāya",
            meaning = "I bow to Shiva, the auspicious witness within.",
            traditionTag = "Shaiva",
        ),
        CustomMantra(
            id = "hare_krishna",
            name = "Hare Krishna Mahamantra",
            text = "हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे । हरे राम हरे राम राम राम हरे हरे ॥",
            transliteration = "Hare Kṛṣṇa Mahāmantra",
            meaning = "The great chant for inner liberation and divine joy.",
            traditionTag = "Vaishnava",
        ),
        CustomMantra(
            id = "soham",
            name = "Soham",
            text = "सो ऽहम्",
            transliteration = "So 'ham",
            meaning = "I am That — breathing in 'So', breathing out 'Ham'.",
        ),
        CustomMantra(
            id = "ram",
            name = "Sri Rama Naam",
            text = "श्री राम जय राम जय जय राम",
            transliteration = "Śrī Rāma Jaya Rāma Jaya Jaya Rāma",
            meaning = "Victory to the divine light within.",
            traditionTag = "Vaishnava",
        ),
        CustomMantra(
            id = "gayatri",
            name = "Gayatri Mantra",
            text = "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥",
            transliteration = "Gāyatrī Mantra",
            meaning = "May divine light illuminate our intellect.",
        ),
    )

    suspend fun getAllMantras(): List<CustomMantra> = defaultMantras + getCustomMantras()

    suspend fun getCustomMantras(): List<CustomMantra> =
        store.getStringList(KEY_CUSTOM_MANTRAS).mapNotNull { raw ->
            runCatching { json.decodeFromString<CustomMantra>(raw) }.getOrNull()
        }

    suspend fun saveCustomMantra(mantra: CustomMantra) {
        val list = store.getStringList(KEY_CUSTOM_MANTRAS).toMutableList()
        list.add(json.encodeToString(mantra.copy(isCustom = true)))
        store.putStringList(KEY_CUSTOM_MANTRAS, list)
    }

    suspend fun setSelectedMantraId(id: String) {
        store.putString(KEY_SELECTED_MANTRA_ID, id)
    }

    suspend fun getSelectedMantra(): CustomMantra {
        val id = store.getString(KEY_SELECTED_MANTRA_ID)
        return getAllMantras().firstOrNull { it.id == id } ?: defaultMantras.first()
    }

    suspend fun getMalaBeadCount(): Int = store.getInt(KEY_MALA_BEAD_COUNT, 0)

    suspend fun saveMalaBeadCount(count: Int) {
        store.putInt(KEY_MALA_BEAD_COUNT, count.coerceAtLeast(0))
    }

    suspend fun getMalaRoundsCompleted(): Int = store.getInt(KEY_MALA_ROUNDS, 0)

    suspend fun saveMalaRoundsCompleted(rounds: Int) {
        store.putInt(KEY_MALA_ROUNDS, rounds.coerceAtLeast(0))
    }

    suspend fun saveSankalp(sankalp: String) {
        store.putString(KEY_ACTIVE_SANKALP, sankalp)
    }

    suspend fun getSankalp(): String =
        store.getString(KEY_ACTIVE_SANKALP)
            ?: "Today my intention is to practice steadiness of breath and mind."

    suspend fun saveCustomRoutine(routine: SavedCustomRoutine) {
        val current = getSavedCustomRoutines().filterNot { it.id == routine.id } + routine
        store.putStringList(KEY_SAVED_ROUTINES, current.map { json.encodeToString(it) })
    }

    suspend fun getSavedCustomRoutines(): List<SavedCustomRoutine> =
        store.getStringList(KEY_SAVED_ROUTINES).mapNotNull { raw ->
            runCatching { json.decodeFromString<SavedCustomRoutine>(raw) }.getOrNull()
        }

    suspend fun deleteCustomRoutine(routineId: String) {
        val remaining = getSavedCustomRoutines().filterNot { it.id == routineId }
        store.putStringList(KEY_SAVED_ROUTINES, remaining.map { json.encodeToString(it) })
    }

    companion object {
        private const val KEY_CUSTOM_MANTRAS = "custom_mantras_list"
        private const val KEY_SELECTED_MANTRA_ID = "selected_mantra_id"
        private const val KEY_MALA_BEAD_COUNT = "daily_mala_count"
        private const val KEY_MALA_ROUNDS = "daily_mala_rounds"
        private const val KEY_ACTIVE_SANKALP = "active_sankalp"
        private const val KEY_SAVED_ROUTINES = "saved_custom_routines"
    }
}
