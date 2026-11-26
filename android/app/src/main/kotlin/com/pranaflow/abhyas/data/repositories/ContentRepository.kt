package com.pranaflow.abhyas.data.repositories

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class ContentManifest(
    val version: String,
    val items: List<ContentManifestEntry> = emptyList(),
)

@Serializable
data class ContentManifestEntry(
    val id: String,
    val type: String, // mantra | lesson | practice_instruction | invocation
    val language: String,
    @SerialName("tradition_tags") val traditionTags: List<String> = emptyList(),
    val status: String, // placeholder | draft | teacher_approved
    val reviewer: String? = null,
    @SerialName("content_path") val contentPath: String,
)

/**
 * Loads teacher-supplied content manifest & enforces FR-CM-02:
 * pilot builds only surface `teacher_approved` content; dev builds mark unapproved items clearly.
 */
class ContentRepository(
    private val assetReader: (String) -> String?,
    val pilotMode: Boolean = false,
) {
    private val json = Json { ignoreUnknownKeys = true }

    fun loadManifest(): ContentManifest {
        val raw = assetReader("content/manifest.json") ?: return ContentManifest(version = "0.1.0")
        return runCatching { json.decodeFromString<ContentManifest>(raw) }
            .getOrDefault(ContentManifest(version = "0.1.0"))
    }

    fun getAvailableItems(tradition: String = "all"): List<ContentManifestEntry> {
        val all = loadManifest().items
        val traditionFiltered = all.filter { entry ->
            "all" in entry.traditionTags || entry.traditionTags.any { it.equals(tradition, ignoreCase = true) }
        }
        return if (pilotMode) {
            traditionFiltered.filter { it.status == "teacher_approved" }
        } else {
            traditionFiltered
        }
    }

    fun loadItemRaw(entry: ContentManifestEntry): String {
        if (pilotMode && entry.status != "teacher_approved") {
            return "[CONTENT PENDING – TEACHER REVIEW]"
        }
        val normalizedPath = entry.contentPath.removePrefix("/")
        return assetReader(normalizedPath) ?: "[CONTENT PENDING – TEACHER REVIEW]"
    }
}
